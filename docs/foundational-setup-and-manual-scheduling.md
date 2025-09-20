# PRD: Foundational Setup & Manual Scheduling

**Status:** Inception
**Owner:** Tim Lawrenz
**Last Updated:** 2025-09-19

## 1. Overview

This document outlines the requirements for the first milestone of the `fluffy-train` project: "Foundational Setup & Manual Scheduling." The goal of this milestone is to deliver the most basic, end-to-end user flow: ingesting a library of photos, allowing a user to select one, and scheduling it to be posted on social media via the Buffer API.

This milestone leverages the existing `fluffy-train` Rails application, which already provides the core data models and services for managing personas and photos.

## 2. Analysis of Existing Components

The current codebase provides a strong foundation:

*   **Personas Management:** The `personas` pack allows for the creation and management of distinct social media identities.
*   **Photo Ingestion:** The `photos` pack can bulk import photos from a local folder and associate them with a persona.
*   **Embedding Generation:** The system is designed to call an external `image_embed` service to generate vector embeddings for each photo, and the database is equipped with `pgvector` to store and search them.

## 3. Missing Components & Work to be Done

While the backend data management is well-underway, several key components are missing to complete the user flow for this milestone. For velocity, we will skip a visual user interface and instead rely on a well-defined internal API accessible via the Rails console.

### 3.1. New Data Model: `Post`

To track scheduled and published content, we need a new data model. This will prevent duplicate posts and provide a foundation for future analytics.

**Technical Requirements:**

*   Create a new `scheduling` pack to encapsulate posting logic.
*   Inside this pack, create a `Post` model with the following attributes:
    *   `photo_id` (foreign key to `Photo`)
    *   `persona_id` (foreign key to `Persona`)
    *   `caption` (text)
    *   `status` (string, e.g., `draft`, `scheduled`, `posted`, `failed`)
    *   `buffer_post_id` (string, to store the ID from the Buffer API)
    *   `scheduled_at` (datetime)
    *   `posted_at` (datetime)
*   The `Post` model should have a unique index on `photo_id` to prevent scheduling the same photo multiple times.

### 3.2. Internal API & Console Interface

A console-based interface is required to interact with the system.

**User Stories:**

*   As a developer on the console, I want to call a command to list all created personas.
*   As a developer on the console, I want to call a command that takes a persona and returns a list of its associated photos that have not yet been scheduled.
*   As a developer on the console, I want to inspect the returned photo objects to see their details (e.g., path, ID).
*   As a developer on the console, I want to use a specific photo object to initiate the scheduling process.

**Technical Requirements:**

*   Expose the existing `Personas` and `Photos` pack functionalities through a clear, console-friendly internal API.
*   Create commands/methods to list personas and photos, returning ActiveRecord relations or arrays of objects that are easy to inspect in the console.

### 3.3. Buffer API Integration & Scheduling Workflow

The application needs to be able to communicate with the Buffer API to schedule posts, now using the `Post` model as the source of truth.

**User Stories:**

*   As a developer on the console, when I decide to schedule a photo, I want to call a command, passing the photo object and a caption string as arguments.
*   As a developer on the console, I want this command to first create a `Post` record in the database with a `scheduled` status.
*   As a developer on the console, I want the application to then send the photo and caption to my Buffer queue.
*   As a developer on the console, I want to see a clear success or failure message returned, and the `Post` record should be updated accordingly (e.g., storing the `buffer_post_id` on success or updating status to `failed` on error).

**Technical Requirements:**

*   Create a new service within the `scheduling` pack responsible for interacting with the Buffer API.
*   Implement a `Scheduling.schedule_post(photo:, caption:)` method.
*   This method must first check if a `Post` record already exists for the given `photo`. If so, it should return a failure context to prevent duplicates.
*   If no post exists, it should create a new `Post` record.
*   It will then handle authentication and format the API request for Buffer.
*   Upon a successful API response, it must update the `Post` record with the `buffer_post_id` and set the status to `scheduled`.
*   Error handling is crucial. On API failure, the `Post` record's status should be updated to `failed`.
*   The entire operation should be handled in a background job (`SolidQueue`) to ensure resilience.

## 4. Success Metrics for this Milestone

*   A user can successfully ingest a folder of at least 100 images using the existing `Photos.bulk_import` service.
*   A developer can use the Rails console to list personas and view the photos for a specific persona.
*   When a developer attempts to schedule a photo from the console, a `Post` record is created in the database.
*   The scheduling command fails if a `Post` already exists for that photo, preventing duplicates.
*   The scheduled post appears correctly in the Buffer queue with the correct image and caption.
*   The corresponding `Post` record is updated with the `buffer_post_id` and a `scheduled` status.
*   The scheduling command returns a clear success or failure context object to the console.
