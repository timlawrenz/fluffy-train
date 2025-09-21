# fluffy-train

## Packs

This application uses [Packwerk](https://github.com/Shopify/packwerk) to organize code into logical, decoupled components called packs. Each pack encapsulates a specific domain or feature.

### Personas

The `personas` pack is responsible for managing social media personas. A persona represents a distinct online identity that can be used to automate social media interactions.

For more details on its implementation and public API, see the [Personas Pack README](./packs/personas/README.md).

### Photos

The `photos` pack manages photos associated with different personas. It handles storing photo references and provides functionality for bulk importing.

For more details on its implementation and public API, see the [Photos Pack README](./packs/photos/README.md).

### Scheduling

The `scheduling` pack is responsible for managing scheduling and posting content. It encapsulates all logic related to scheduling, posting, and interacting with third-party social media APIs.

For more details on its implementation and public API, see the [Scheduling Pack README](./packs/scheduling/README.md).

## Production-like Setup

To run this application in a production-like environment, you need to configure credentials for both a cloud storage provider (for ActiveStorage) and the Buffer API.

### 1. Prerequisites

*   An account with a Buffer.com.
*   An S3-compatible cloud storage bucket (e.g., Amazon S3) with public read access configured.

### 2. Configure Cloud Storage (ActiveStorage)

The application uses ActiveStorage to handle file uploads and requires a cloud storage provider for permanent, public URLs.

1.  **Store Cloud Credentials:**
    Open the encrypted credentials file for editing:
    ```bash
    bin/rails credentials:edit
    ```
    Add your S3-compatible storage credentials. For AWS S3, it would look like this:
    ```yml
    aws:
      access_key_id: YOUR_ACCESS_KEY_ID
      secret_access_key: YOUR_SECRET_ACCESS_KEY
      region: YOUR_REGION
    ```

2.  **Configure `storage.yml`:**
    Update `config/storage.yml` to use your cloud provider. For AWS S3, you can configure a service named `amazon`:
    ```yml
    amazon:
      service: S3
      access_key_id: <%= Rails.application.credentials.aws[:access_key_id] %>
      secret_access_key: <%= Rails.application.credentials.aws[:secret_access_key] %>
      region: <%= Rails.application.credentials.aws[:region] %>
      bucket: YOUR_BUCKET_NAME
    ```

3.  **Set Production Service:**
    In `config/environments/production.rb`, ensure ActiveStorage is configured to use your new service:
    ```ruby
    config.active_storage.service = :amazon
    ```

### 3. Configure Buffer API

The application needs a Buffer API access token to schedule posts.

1.  **Generate a Token:**
    Log into your Buffer developer account and generate a new access token.

2.  **Store the Token:**
    Add the token to your encrypted credentials (`bin/rails credentials:edit`):
    ```yml
    buffer:
      access_token: YOUR_BUFFER_ACCESS_TOKEN
    ```

### 4. Application Data Setup

Before you can schedule posts, you need to create a `Persona` and link it to a Buffer profile.

1.  **Run Database Migrations:**
    ```bash
    bin/rails db:migrate
    ```

2.  **Create a Persona and Link to Buffer:**
    Launch the Rails console (`bin/rails c`) and follow these steps:
    ```ruby
    # Find your desired Buffer Profile ID from the Buffer dashboard or API.
    # It's a long alphanumeric string, e.g., "615b6f2b3e4d5f6b7c8d9e0f".
    buffer_profile_id = "YOUR_BUFFER_PROFILE_ID"

    # Create a new Persona and associate it with the Buffer profile.
    Personas::Persona.create!(
      name: "Nature Explorer", 
      buffer_profile_id: buffer_profile_id
    )
    ```

### 5. Usage

With the setup complete, you can now use the manual console workflow to import and schedule photos. See the [Manual Scheduling Documentation](./docs/01-manual-scheduling.md#43-manual-console-workflow) for a detailed guide.
