# Tech Spec: Automated Posting Engine & Basic Scheduling

This document outlines the technical implementation details for Milestone 3, which focuses on creating a fully automated posting engine.

*   **Relevant Existing Core Models:** `Photo`, `PhotoAnalysis`, `Scheduling::Post`, `Persona`
*   **Relevant Existing Packs:** `packs/photos`, `packs/scheduling`, `packs/personas`
*   **Goal:** Ensure the tech spec is clear, technically sound, considers edge cases, and aligns with the engineering practices and the existing architecture of the `fluffy-train` application.

---

### 1. Feature Details

*   **Feature Name:** Automated Posting Engine & Basic Scheduling
*   **Problem Statement:** The current process of selecting and posting images is manual and time-consuming. The application lacks the ability to operate autonomously, requiring daily human intervention to maintain a consistent posting schedule. This prevents `fluffy-train` from being a "set it and forget it" tool.
*   **Proposed High-Level Solution:** Introduce a recurring job (e.g., a Rake task managed by a cron-like scheduler) that automatically executes the posting logic. This job will select the highest-quality, unposted photo from the library based on its `PhotoAnalysis` score and post it directly to Instagram using the Meta API. The system will log posted photos to prevent duplicates.
*   **Primary Pack:** `packs/scheduling`
*   **Key Goals:**
    *   Automate the daily posting process to run without human intervention.
    *   Implement a clear and simple default posting strategy: "Post the highest-rated, not-yet-posted image."
    *   Reliably track which images have been posted to avoid duplicates.
    *   Establish a robust scheduling mechanism that runs at a configurable frequency.
*   **Key Non-Goals:**
    *   Complex, multi-day posting strategies (e.g., thematic rotation, "Theme of the Week").
    *   Automated, generative caption or hashtag creation (a predefined caption will be used initially).
    *   A user interface for managing the schedule or viewing posting history.
    *   Real-time performance monitoring or a dashboard for the scheduler.

### 2. Technical Implementation Plan

#### A. Data Model Changes

1.  **Modify `Scheduling::Post` Model:**
    *   To support automated posting, the existing `Scheduling::Post` model will be adapted. This avoids creating a redundant model and keeps posting-related data unified.
    *   **Migrations:**
        *   **`add_photo_id_to_scheduling_posts`**: A migration will be created to add a `photo_id` foreign key to the `scheduling_posts` table. This will establish a direct link between a scheduled post and a photo.
        *   **`add_status_to_scheduling_posts`**: A migration will add a `status` string column. This will be managed as a state machine (per `CONVENTIONS.md`) to track the posting lifecycle (`posting`, `posted`, `failed`), preventing duplicate posts and providing a clear audit trail.

#### B. Core Logic: The Posting Job

1.  **Create a new Rake Task:**
    *   A new task, `scheduling:post_next_best`, will be created within the `packs/scheduling` pack (e.g., in `packs/scheduling/lib/tasks/scheduling.rake`).
    *   This task will be the entry point for the automated scheduler.

2.  **Implement the "Curator's Choice" Strategy:**
    *   The Rake task will invoke a new service object, `Scheduling::Strategies::CuratorsChoice`.
    *   This service will be responsible for the core selection logic:
        *   **Query:** Find all `Photos` that do not have an associated `Scheduling::Post` record.
        *   **Join & Order:** Join with `photo_analyses` and order the results in descending order by the aesthetic score for the photos that are not yet posted.
        *   **Select:** Take the top-ranked photo (`.first`).
        *   **Handle Empty State:** If no unposted photos are found, the job should log a warning and exit gracefully.

3.  **Posting the Image:**
    *   To prevent duplicate posts in case of job failures, the service will follow these steps:
        *   Once the best photo is selected, immediately create a new `Scheduling::Post` record with the selected `photo_id` and a `status` of `posting`.
        *   Call the Meta API integration service to post the image.
        *   **On Success:** Update the `Scheduling::Post` record's `status` to `posted`, save the `provider_post_id` from the API response, and set the `posted_at` timestamp.
        *   **On Failure:** Update the `Scheduling::Post` record's `status` to `failed`. This ensures the photo is not re-selected on the next run and provides a clear record of the failed attempt.

#### C. Automation: The Scheduler

1.  **Utilize a Scheduling Add-on or Cron:**
    *   For a production environment (like Heroku), a scheduler add-on (e.g., Heroku Scheduler) will be configured to run the Rake task `scheduling:post_next_best`.
    *   For local development, `Procfile.dev` can be updated, or developers can run it manually.
    *   **Configuration:** The job will be configured to run once daily at a specified time (e.g., 9:00 AM UTC).

### 3. Testing Plan

*   **Unit Tests:**
    *   The `Scheduling::Strategies::CuratorsChoice` service object will be unit-tested to verify its selection logic.
    *   Tests will cover scenarios where:
        *   It correctly selects the highest-scoring photo.
        *   It correctly ignores photos that have an associated `Scheduling::Post`.
        *   It handles the case where no unposted photos are available.
*   **Integration Tests:**
    *   An integration test for the `scheduling:post_next_best` Rake task will be created.
    *   This test will simulate the entire process: running the task, verifying that the correct photo is selected, confirming that the Meta API service is called with the correct arguments, and checking that a new `Scheduling::Post` record is created in the database.

### 4. Open Questions & Edge Cases

*   **Error Handling:** What should happen if the Meta API call fails?
    *   **Decision:** The job will catch the exception from the API call and update the `Scheduling::Post` record's status to `failed`. This creates a clear audit trail of the attempt and prevents the same photo from being picked again. After marking the post as failed, the job can log the error or allow it to be reported to an error tracking service.
*   **No Photos Found:** What is the desired behavior if the library of unposted photos is exhausted?
    *   **Decision:** The job should log a clear warning message (e.g., "No unposted photos available to schedule.") and exit successfully without posting. No error notifications are needed for this state.
*   **Static Caption:** Where should the initial predefined caption be stored?
    *   **Decision:** For this milestone, it can be a simple constant within the `CuratorsChoice` service. This makes it easy to find and replace when generative captions are introduced later.

### Issue Dependency Tree
```
- [Database] Modify Scheduling::Post for Automated Posting (#38)
  - [Backend] Implement Scheduling::Strategies::CuratorsChoice Service (#40)
    - [Backend] Implement Automated Posting and Status Handling Logic (#39)
      - [Backend] Create scheduling:post_next_best Rake Task (#44)
        - [Testing] Write Integration Test for post_next_best Rake Task (#43)
        - [Setup] Configure Scheduler for Automated Posting (#42)
      - [Testing] Write Unit Tests for CuratorsChoice Strategy (#41)
```
