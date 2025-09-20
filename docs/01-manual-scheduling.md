# Tech Spec: Foundational Setup & Manual Scheduling

**Status:** Approved
**Owner:** Tim Lawrenz
**Last Updated:** 2025-09-20

## 1. Overview

This document outlines the technical implementation plan for the "Foundational Setup & Manual Scheduling" milestone. The goal is to build the core, end-to-end workflow for ingesting photos, selecting one via a console interface, and scheduling it for social media posting via the Buffer API.

This spec addresses the initial requirements from the PRD and incorporates necessary architectural changes based on the technical constraints of the Buffer API and the local storage of photos.

### 1.1. Architectural Principles

This project uses a **pack-based architecture** to promote modularity and maintain clear boundaries between different domains of the application. All engineers are expected to adhere to the following principles:

*   **High Encapsulation:** Packs should hide their internal implementation details, including their data models and business logic.
*   **Explicit Public API:** All interaction between packs **must** go through the public API defined in the pack's `app/public/` directory. Direct calls to another pack's internal models, services, or commands are strictly forbidden.
*   **No Leaky Abstractions:** Public APIs must not expose internal implementation details. Specifically, they **must not** return `ActiveRecord::Relation` objects. Instead, they should return simple data structures, such as arrays of objects, individual POROs (Plain Old Ruby Objects), or the pack's own models.
*   **Declared Dependencies:** A pack must declare a dependency in its `package.yml` file to be able to call another pack's public API.

## 2. Data Model & Migration

To track scheduled and published content, a new data model and Packwerk pack will be created.

### 2.1. New Pack: `packs/scheduling`

*   **Description:** A new Packwerk pack will be created to house all logic related to scheduling, posting, and interacting with third-party social media APIs.
*   **Location:** `packs/scheduling`
*   **Dependencies:** `packs/scheduling` will declare dependencies on `packs/personas` and `packs/photos`.

### 2.2. Data Model Updates

#### 2.2.1. New Model: `Scheduling::Post`

This model will be the source of truth for all content scheduled for publication.

*   **File:** `packs/scheduling/app/models/scheduling/post.rb`
*   **Attributes:**
    *   `photo_id` (bigint, foreign key, not null)
    *   `persona_id` (bigint, foreign key, not null)
    *   `caption` (text)
    *   `status` (string, not null, default: 'draft')
    *   `buffer_post_id` (string)
    *   `scheduled_at` (datetime)
    *   `posted_at` (datetime)
*   **Associations:**
    *   `belongs_to :photo, class_name: 'Photos::Photo'`
    *   `belongs_to :persona, class_name: 'Personas::Persona'`
    *   **Note:** These associations are for data integrity at the database level (foreign keys). The business logic within the `scheduling` pack should not directly call methods on `Photos::Photo` or `Personas::Persona` objects. It should operate on IDs and data passed into its public API.
*   **State Machine (`state_machines-activerecord`):**
    *   The `status` attribute will be managed by a state machine.
    *   **States:** `draft`, `scheduled`, `posted`, `failed`
    *   **Initial State:** `draft`
    *   **Events:**
        *   `schedule`: Transitions from `draft` to `scheduled`.
        *   `mark_as_posted`: Transitions from `scheduled` to `posted`.
        *   `fail`: Transitions from `draft` or `scheduled` to `failed`.

#### 2.2.2. Update to `Personas::Persona`

To associate a persona with a specific Buffer social media profile, a new attribute is required.

*   **Model:** `Personas::Persona`
*   **New Attribute:** `buffer_profile_id` (string)

### 2.3. Database Migrations

Two migrations will be generated.

1.  **Create `scheduling_posts` table:**
    ```ruby
    # db/migrate/YYYYMMDDHHMMSS_create_scheduling_posts.rb
    class CreateSchedulingPosts < ActiveRecord::Migration[7.1]
      def change
        create_table :scheduling_posts do |t|
          t.references :photo, null: false, foreign_key: true
          t.references :persona, null: false, foreign_key: true
          t.text :caption
          t.string :status, null: false, default: 'draft'
          t.string :buffer_post_id
          t.datetime :scheduled_at
          t.datetime :posted_at
    
          t.timestamps
        end
    
        add_index :scheduling_posts, [:photo_id, :persona_id], unique: true, name: 'index_posts_on_photo_id_and_persona_id'
      end
    end
    ```
2.  **Add `buffer_profile_id` to `personas` table:** A second migration will be created to add the `buffer_profile_id` column to the `personas` table.

## 3. Prerequisite: ActiveStorage for Public URLs

The Buffer API requires a permanent, publicly accessible URL for images. To facilitate this, the project will be configured to use ActiveStorage with a cloud storage provider.

*   **Setup:** The project will be configured to use ActiveStorage with an S3-compatible cloud provider (e.g., Amazon S3). This includes adding necessary gems (e.g., `aws-sdk-s3`), updating `config/storage.yml`, and managing cloud credentials via the `.env` file and `config/credentials.yml.enc`.
*   **Public Access:** The S3 bucket must be configured for public read access to ensure that Buffer's servers can download the photo.
*   **Model Update:** The `Photos::Photo` model will be updated to include an image attachment:
    ```ruby
    # packs/photos/app/models/photos/photo.rb
    has_one_attached :image
    ```
*   **Importer Update:** The `Photos.bulk_import` command will be modified. For each photo being imported, it must also attach the file to the `Photo` record using ActiveStorage (e.g., `photo.image.attach(io: File.open(path), filename: File.basename(path))`).

## 4. Internal API & Console Interface

A console-based interface is required to interact with the system, following the established public API pattern for packs.

### 4.1. `personas` Pack Public API

*   **File:** `packs/personas/app/public/personas.rb`
*   **Method:** `Personas.list`
    *   **Description:** Returns all `Persona` records.
    *   **Returns:** `Array<Personas::Persona>`
*   **Method:** `Personas.find_by_name(name:)`
    *   **Description:** Finds a single `Persona` by its exact name.
    *   **Returns:** `Personas::Persona | nil`

### 4.2. `scheduling` Pack Public API

*   **File:** `packs/scheduling/app/public/scheduling.rb`
*   **Method:** `Scheduling.unscheduled_for_persona(persona: Personas::Persona)`
    *   **Description:** Finds all photos for a given persona that do not yet have a corresponding `Scheduling::Post` record.
    *   **Returns:** `Array<Photos::Photo>`
*   **Method:** `Scheduling.schedule_post(photo: Photos::Photo, persona: Personas::Persona, caption: String)`
    *   **Description:** Schedules a photo for posting to Buffer by invoking the `Scheduling::Chain::SchedulePost` command chain.
    *   **Returns:** `GLCommand::Context` — The context will indicate success or failure. On failure, `context.errors` will be populated.
*   **Method:** `Scheduling.sync_post_statuses(persona: Personas::Persona)`
    *   **Description:** Connects to the Buffer API to get the status for recent posts for a given persona and updates the database.
    *   **Returns:** `GLCommand::Context` — On success, the context will contain a list of the updated `Scheduling::Post` records (e.g., `context.updated_posts`).

### 4.3. Manual Console Workflow

The initial user interface for manual scheduling and status checks will be through the Rails console (`bin/rails c`), leveraging the public APIs exposed by the packs. This approach respects pack boundaries and provides transparent feedback for manual operations.

#### 4.3.1. Example: Scheduling a Post

Here is the standard workflow a developer will follow in the console to schedule a post:

1.  **Launch the Console:**
    ```bash
    bin/rails c
    ```

2.  **Select a Persona:** Fetch the desired persona using the public API.
    ```ruby
    persona = Personas.find_by_name(name: "Nature Explorer")
    ```

3.  **Find an Unscheduled Photo:** Get a list of available photos for that persona and select one.
    ```ruby
    photo = Scheduling.unscheduled_for_persona(persona: persona).sample
    ```

4.  **Schedule the Post:** Call the public API method with the photo, persona, and a caption.
    ```ruby
    result = Scheduling.schedule_post(photo: photo, persona: persona, caption: "A stunning mountain vista.")
    ```

5.  **Verify the Outcome:** Inspect the returned `GLCommand::Context` to determine the result.
    ```ruby
    if result.success?
      puts "Post scheduled successfully! Buffer ID: #{result.post.buffer_post_id}"
    else
      puts "Failed to schedule post. Errors: #{result.errors.full_messages.join(', ')}"
    end
    ```

## 5. Buffer API Integration & Scheduling Workflow

The scheduling process will be implemented as an atomic command chain to ensure resilience and data integrity.

### 5.1. Authentication and Configuration

Authentication will be handled via a single, long-lived access token generated from the Buffer developer dashboard.

*   **Storage:** The access token will be stored securely in the application's encrypted credentials (`config/credentials.yml.enc`).
*   **Configuration:** The `Buffer::Client` will be initialized with this token.

### 5.2. Entry Point

*   **File:** `packs/scheduling/app/public/scheduling.rb`
*   **Method:** `Scheduling.schedule_post(photo:, persona:, caption:)`
*   **Implementation:** This method will invoke the `Scheduling::Chain::SchedulePost` command chain and return the resulting `GLCommand::Context`.

### 5.3. Command Chain: `Scheduling::Chain::SchedulePost`

A `GLCommand::Chain` will orchestrate the entire process to ensure that all steps succeed or the entire operation is rolled back.

*   **File:** `packs/scheduling/app/commands/scheduling/chain/schedule_post.rb`
*   **Context:** The chain will be initialized with `photo`, `persona`, and `caption`.
*   **Commands in Chain:**
    1.  `Scheduling::Commands::CreatePostRecord`
    2.  `Scheduling::Commands::GeneratePublicPhotoUrl`
    3.  `Scheduling::Commands::SendPostToBuffer`
    4.  `Scheduling::Commands::UpdatePostWithBufferId`

### 5.4. Command Breakdown

1.  **`CreatePostRecord`**
    *   **Responsibility:** Creates the `Scheduling::Post` record with `status: 'draft'`, associating the `photo` and `persona`.
    *   **Rollback:** Destroys the created `Scheduling::Post` record.

2.  **`GeneratePublicPhotoUrl`**
    *   **Responsibility:** Generates a permanent, public URL for the photo's ActiveStorage attachment. Adds the URL to the command context.
    *   **Rollback:** None required (read-only operation).

3.  **`SendPostToBuffer`**
    *   **Responsibility:** Calls the `Buffer::Client` with the caption, public photo URL, and the persona's `buffer_profile_id`. Adds the `buffer_post_id` from the response to the context.
    *   **Rollback:** Calls the `Buffer::Client` to delete the scheduled post from Buffer using the `POST /updates/:id/destroy` endpoint.

4.  **`UpdatePostWithBufferId`**
    *   **Responsibility:** Updates the `Scheduling::Post` record with the `buffer_post_id` from the context and transitions its status to `scheduled`.
    *   **Rollback:** Reverts the `status` to `draft` and clears the `buffer_post_id`.

### 5.5. API Client: `Buffer::Client`

*   **File:** `packs/scheduling/app/clients/buffer/client.rb`
*   **Responsibilities:**
    *   Initialize with the Buffer API access token from Rails credentials.
    *   Provide a `create_post(image_url:, caption:, buffer_profile_id:)` method.
    *   Provide a `destroy_post(buffer_post_id:)` method.
    *   Provide a `fetch_status_for_posts(buffer_profile_id:)` method that retrieves the latest updates for a profile.
    *   Encapsulate request formatting, response parsing, and error handling.

### 5.6. Post-Scheduling Status Updates

To update the status of posts from `scheduled` to `posted` or `failed`, a polling mechanism will be used.

*   **Entry Point:** `Scheduling.sync_post_statuses(persona:)`
*   **Implementation:** This will be a command (e.g., `Scheduling::Commands::SyncPostStatuses`) that returns a `GLCommand::Context`. The command will:
    1.  Find all `Scheduling::Post` records with `status: 'scheduled'` for the given persona.
    2.  Calls the `Buffer::Client` to fetch the latest post statuses for the persona's `buffer_profile_id`.
    3.  Iterates through the local `scheduled` posts and compares them with the data from Buffer.
    4.  Updates the local post status to `posted` or `failed` based on the API response. It will also set the `posted_at` timestamp.
    5.  On success, it will add the list of updated posts to the context (e.g., `context.updated_posts = ...`) before returning it.

## 6. Testing Strategy

*   **Model Specs:** Located in `packs/scheduling/spec/models/`, will test `Scheduling::Post` associations, validations, and state machine transitions.
*   **Command Specs:** Located in `packs/scheduling/spec/commands/`, will test each command in isolation, using mocks for dependencies like the `Buffer::Client`.
*   **Client Specs:** Located in `packs/scheduling/spec/clients/`, will use `VCR` or `WebMock` to test the `Buffer::Client` against recorded API interactions.
*   **Job Specs:** Located in `packs/scheduling/spec/jobs/`, will ensure jobs correctly invoke their target commands.
*   **Integration Test:** A single, top-level test at `spec/integration/scheduling_workflow_spec.rb` will test the entire `Scheduling.schedule_post` flow, using a mocked `Buffer::Client` to verify the complete chain of operations across pack boundaries.

## 7. Ticket Dependency Tree

*   [[Setup] Configure ActiveStorage with Cloud Provider](https://github.com/timlawrenz/fluffy-train/issues/1)
    *   [[Backend] Create `packs/scheduling` Pack](https://github.com/timlawrenz/fluffy-train/issues/2)
        *   [[Database] Add `buffer_profile_id` to `Personas::Persona`](https://github.com/timlawrenz/fluffy-train/issues/4)
            *   [[Backend] Implement `personas` Pack Public API](https://github.com/timlawrenz/fluffy-train/issues/6)
                *   [[Backend] Implement `scheduling` Pack Public API](https://github.com/timlawrenz/fluffy-train/issues/9)
                    *   [[Testing] Write Integration Test for Scheduling Workflow](https://github.com/timlawrenz/fluffy-train/issues/10)
        *   [[Database] Create `Scheduling::Post` Model and Migration](https://github.com/timlawrenz/fluffy-train/issues/3)
            *   [[Backend] Implement `Buffer::Client` for API Integration](https://github.com/timlawrenz/fluffy-train/issues/7)
                *   [[Backend] Implement `Scheduling::Chain::SchedulePost` Command Chain](https://github.com/timlawrenz/fluffy-train/issues/8)
    *   [[Backend] Update `Photos::Photo` to use ActiveStorage](https://github.com/timlawrenz/fluffy-train/issues/5)