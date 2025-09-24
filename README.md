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

To run this application in a production-like environment, you need to configure credentials for both a cloud storage provider (for ActiveStorage) and the Instagram Graph API.

### 1. Prerequisites

*   A [Meta Developer Account](https://developers.facebook.com/).
*   An Instagram Business or Creator Account that is linked to a Facebook Page.
*   An S3-compatible cloud storage bucket (e.g., Amazon S3 or Backblaze B2) with public read access configured.

### 2. Configure Cloud Storage (ActiveStorage)

The application uses ActiveStorage to handle file uploads and requires a cloud storage provider for permanent, public URLs.

1.  **Store Cloud Credentials:**
    Open the encrypted credentials file for editing:
    ```bash
    bin/rails credentials:edit
    ```
    Add your S3-compatible storage credentials. For Backblaze B2, it would look like this:
    ```yml
    b2:
      access_key_id: YOUR_ACCESS_KEY_ID
      application_key: YOUR_APPLICATION_KEY
    ```

2.  **Configure `storage.yml`:**
    Update `config/storage.yml` to use your cloud provider. For Backblaze B2, you can configure a service named `b2`:
    ```yml
    b2:
      service: S3
      access_key_id: <%= Rails.application.credentials.dig(:b2, :access_key_id) %>
      secret_access_key: <%= Rails.application.credentials.dig(:b2, :application_key) %>
      region: YOUR_B2_REGION # e.g., us-west-004
      bucket: YOUR_BUCKET_NAME
      endpoint: 'YOUR_B2_S3_ENDPOINT' # e.g., https://s3.us-west-004.backblazeb2.com
      public: true
    ```

3.  **Set Production Service:**
    In `config/environments/production.rb`, ensure ActiveStorage is configured to use your new service:
    ```ruby
    config.active_storage.service = :b2
    ```

### 3. Configure Instagram Graph API

The application needs credentials from a Meta Developer App to post to Instagram.

1.  **Create a Meta App:**
    *   Go to the [Meta Developer Portal](https://developers.facebook.com/).
    *   Create a new app of type "Business".
    *   From the app dashboard, add the "Instagram Graph API" product.
    *   Under "App Review" -> "Permissions and Features", request Advanced Access for `instagram_content_publish`, `pages_show_list`, `instagram_basic`, and `pages_read_engagement`.

2.  **Generate Credentials:**
    *   Follow the API setup process to generate a **long-lived User Access Token**.
    *   Use the Graph API Explorer to find your **Instagram Business Account ID**.

3.  **Store Credentials:**
    Add all four credentials to your encrypted credentials file (`bin/rails credentials:edit`):
    ```yml
    instagram:
      app_id: "YOUR_APP_ID"
      app_secret: "YOUR_APP_SECRET"
      access_token: "YOUR_LONG_LIVED_ACCESS_TOKEN"
      account_id: "YOUR_INSTAGRAM_BUSINESS_ACCOUNT_ID"
    ```

### 4. Application Data Setup

Before you can schedule posts, you need to create a `Persona`.

1.  **Run Database Migrations:**
    ```bash
    bin/rails db:migrate
    ```

2.  **Create a Persona:**
    Launch the Rails console (`bin/rails c`) and create a persona:
    ```ruby
    Personas::Persona.create!(
      name: "Nature Explorer",
      description: "A persona for nature and outdoor content."
    )
    ```

### 5. Usage

With the setup complete, you can now use the manual console workflow to import and schedule photos. See the [Manual Scheduling Documentation](./docs/01-manual-scheduling.md#43-manual-console-workflow) for a detailed guide.
