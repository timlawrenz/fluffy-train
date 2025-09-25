# PRD: Milestone 2 - Advanced Photo Analysis & Quality Control

## 1. Overview & Goal

The primary goal of this milestone is to automate the quality control process for our image library. By integrating advanced image analysis techniques, we can ensure that only high-quality, aesthetically pleasing, and content-appropriate images are selected for posting. This reduces the need for manual curation and establishes the foundation for more intelligent, automated content selection in future milestones.

## 2. Problem Statement

Manually reviewing a large library of photos to filter out low-quality images (e.g., blurry, over/underexposed) is a significant bottleneck. This process is not only time-consuming but also highly subjective. To build a truly automated content scheduling system, we need an objective, consistent, and scalable way to assess the technical and aesthetic quality of each photo. Furthermore, understanding the actual content of the images is crucial for enabling content-aware filtering and thematic curation.

## 3. Scope

### In Scope:
-   **Data Model for Analysis:** Creating a new database model (`PhotoAnalysis`) to store all quality and content metrics associated with a `Photo`.
-   **Technical Quality Scoring:** Implementing automated analysis for image sharpness and exposure.
-   **AI-Powered Analysis:** Integrating a multimodal AI model via Ollama to generate aesthetic scores and perform object detection.
-   **Workflow Integration:** Ensuring the entire analysis pipeline is automatically triggered as an atomic part of the existing photo import process.
-   **Programmatic Trigger:** All functionality will be designed to be triggered programmatically (e.g., from the Rails console or another service), without a user-facing interface in this milestone.

### Out of Scope (Non-Goals):
-   **User Interface:** No web UI will be built for viewing, filtering, or managing these analysis scores in this milestone.
-   **Filtering Logic:** This milestone focuses solely on *generating and storing* the analysis data. The implementation of filtering logic based on these scores (e.g., "only select photos with aesthetic_score > 7") is out of scope.
-   **Advanced Face Detection:** While object detection is included, specific face analysis (e.g., detecting eye closure, sentiment) is deferred.
-   **Batch Re-analysis:** A system for batch-processing the *entire* existing library will not be built at this time. The focus is on analyzing new photos upon import.

## 4. Feature Requirements & Implementation Details

### FR1: Data Storage for Analysis Metrics

-   **Requirement:** A new `PhotoAnalysis` model will be created to store all metrics, ensuring the `Photo` model remains clean and focused on its core responsibilities.
-   **Implementation:**
    -   A new table, `photo_analyses`, will be created with columns for `sharpness_score` (float), `exposure_score` (float), `aesthetic_score` (float), and `detected_objects` (jsonb).
    -   A `PhotoAnalysis` model will `belong_to :photo`.
    -   The `Photo` model will have a `has_one :photo_analysis` association with `dependent: :destroy`.

### FR2: Technical Quality Analysis

-   **Requirement:** The system must automatically calculate objective technical quality scores for each new photo.
-   **Implementation:**
    -   A `Photos::Analyse::Sharpness` command will be created. It will use the `ruby-vips` library to perform a Laplacian variance calculation on the image to determine a sharpness score.
    -   A `Photos::Analyse::Exposure` command will be created. It will use `ruby-vips` to analyze the image's histogram and calculate a mean brightness score.

### FR3: AI-Powered Content & Aesthetic Analysis

-   **Requirement:** The system must leverage a local, GPU-accelerated multimodal AI model to generate a subjective aesthetic score and identify the primary objects within each photo.
-   **Implementation:**
    -   An `Photos::Analyse::Aesthetics` command will interface with a local Ollama instance running the `gemma3:27b` model. It will send the image and a prompt asking for an aesthetic score on a 1-10 scale.
    -   An `Photos::Analyse::ObjectDetection` command will use the same `gemma3:27b` model. It will be prompted to return a JSON array of detected objects, including a `label` and a `confidence` score for each.

### FR4: Integration into Import Workflow

-   **Requirement:** The analysis process must be an integral and atomic part of the photo import workflow, ensuring every new photo is analyzed and that the process is reversible on failure.
-   **Implementation:**
    -   The entire analysis pipeline will be encapsulated in a `GLCommand::Chainable` command, `Photos::AnalysePhoto`. This command will orchestrate the individual `Sharpness`, `Exposure`, `Aesthetics`, and `ObjectDetection` commands.
    -   The main `Photos::Import` command will be structured as a `GLCommand::Chainable`, with `Photos::AnalysePhoto` added as the final step in its chain. This leverages the `gl_command` library's automatic rollback capabilities, ensuring data integrity if any step fails.

## 5. Acceptance Criteria

-   **AC1:** When a new photo is successfully imported via the `Photos::Import` command, a corresponding `PhotoAnalysis` record is created and correctly associated with the new `Photo` record.
-   **AC2:** The `sharpness_score` and `exposure_score` fields on the new `PhotoAnalysis` record are populated with valid floating-point numbers.
-   **AC3:** The `aesthetic_score` field is populated with a valid number (integer or float) within the expected 1-10 range.
-   **AC4:** The `detected_objects` field contains a valid JSON array, and each element in the array contains at least a "label" and "confidence" key.
-   **AC5:** If any of the analysis sub-commands (`Sharpness`, `Exposure`, `Aesthetics`, or `ObjectDetection`) fail, the entire import process is rolled back. The database should show no new `Photo` or `PhotoAnalysis` record for the failed import.
-   **AC6:** The process can be successfully triggered from the Rails console for a given local image file path.

## 6. Ticket Dependency Tree

*   [#22: \[Database\] Create PhotoAnalysis Model and Migration](https://github.com/timlawrenz/fluffy-train/issues/22)
    *   [#21: \[Backend\] Implement Photos::Analyse::Sharpness Command](https://github.com/timlawrenz/fluffy-train/issues/21)
    *   [#24: \[Backend\] Implement Photos::Analyse::Exposure Command](https://github.com/timlawrenz/fluffy-train/issues/24)
    *   [#28: \[Backend\] Implement Photos::Analyse::Aesthetics Command](https://github.com/timlawrenz/fluffy-train/issues/28)
    *   [#23: \[Backend\] Implement Photos::Analyse::ObjectDetection Command](https://github.com/timlawrenz/fluffy-train/issues/23)
        *   [#26: \[Backend\] Create Photos::AnalysePhoto Orchestration Command](https://github.com/timlawrenz/fluffy-train/issues/26)
            *   [#27: \[Backend\] Integrate Analysis into Photos::Import Workflow](https://github.com/timlawrenz/fluffy-train/issues/27)
                *   [#25: \[Testing\] Create Integration Test for Import & Analysis Workflow](https://github.com/timlawrenz/fluffy-train/issues/25)