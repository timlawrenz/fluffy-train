# PRD: Automated Caption Generation

*   **Author**: Gemini CLI
*   **Date**: 2025-10-03
*   **Status**: Approved

## 1. Background & Problem Statement

The current automated posting engine (`CuratorsChoice` strategy) uses a single, static caption for every photo it posts to Instagram. This approach lacks personalization and context, leading to repetitive and unengaging content. To improve the quality and variety of our posts, we need to automate the generation of captions that are directly relevant to the visual content of each image.

This feature represents an intermediate step towards the larger goal of persona-driven, generative AI content outlined in the project roadmap (Milestone 5a), focusing first on establishing the core captioning pipeline.

## 2. Goals & Objectives

*   To automatically generate a unique, descriptive caption for each new photo during the analysis phase.
*   To store the generated caption in the database, associated with the photo's analysis record.
*   To ensure the automated posting engine uses the stored, content-aware caption instead of a static one.
*   To seamlessly integrate the captioning process into the existing photo import and analysis pipeline (`Photos::AnalysePhoto`).

## 3. Non-Goals

*   Generating captions on-the-fly at the moment of posting. Captions will be pre-generated during analysis.
*   Implementing persona-driven or cluster-driven caption generation. This initial version will be purely content-driven.
*   Automated hashtag generation.
*   A user interface for editing, reviewing, or approving generated captions.

## 4. User Stories

*   **As a content manager,** I want each photo to have a unique and descriptive caption so that our social media feed is more engaging and less repetitive.
*   **As a developer,** I want the caption generation to be an automated part of the photo import process so that no manual intervention is required to create captions.

## 5. Technical Solution

The proposed solution integrates caption generation directly into the existing photo analysis pipeline within the `packs/photos` Packwerk pack.

### 1. Database Schema Change
A new migration will be created to add a `caption` column of type `text` to the `photo_analyses` table. This column will store the generated caption for each photo.

### 2. Ollama Client Extension
The existing `OllamaClient` in `packs/photos/app/clients/ollama_client.rb` will be extended with a new class method: `self.generate_caption(file_path:)`.
*   This method will take the absolute path to an image file.
*   It will send the image to a multimodal AI model (e.g., LLaVA) hosted via Ollama.
*   The prompt will be simple and direct, for example: "Generate a short, engaging caption for this image, suitable for Instagram."
*   It will parse the response and return the caption as a string, raising an `OllamaClient::Error` on failure.

### 3. New Analysis Command
A new command, `Photos::Analyse::Caption`, will be created in `packs/photos/app/commands/photos/analyse/caption.rb`.
*   It will require a `photo` object as input.
*   It will call the new `OllamaClient.generate_caption` method.
*   It will save the returned caption to the `caption` attribute of the `photo.photo_analysis` record.

### 4. Pipeline Integration
The new `Photos::Analyse::Caption` command will be added to the command chain within `Photos::AnalysePhoto` (`packs/photos/app/commands/photos/analyse_photo.rb`), just before the final `Photos::Analyse::SaveResults` step. This ensures captioning happens as part of the standard analysis for every new photo.

### 5. Update Posting Strategy
The `Scheduling::Strategies::CuratorsChoice` service in `packs/scheduling` will be modified. The hardcoded `STATIC_CAPTION` will be removed. Instead, the service will retrieve the pre-generated caption from the `photo.photo_analysis.caption` attribute when creating a new post.

## 6. Success Metrics

*   **100% Caption Coverage:** Every new photo that successfully passes the analysis pipeline has a non-empty `caption` field in its `photo_analysis` record.
*   **Successful Integration:** The end-to-end process works automatically. Running the `photos:bulk_import` Rake task results in photos being imported, analyzed, and having unique captions stored in the database.
*   **Correct Usage:** All posts created by the `CuratorsChoice` strategy use the dynamically generated caption from the database.

## 7. Future Considerations

This feature lays the groundwork for more advanced generative capabilities. Future iterations could include:
*   **Persona-Driven Captions:** Incorporating the `Persona` model to influence the tone, style, and content of the generated caption, as envisioned in Milestone 5a.
*   **Theme-Aware Captions:** Using the photo's cluster information (Milestone 4) to generate captions that align with a specific theme (e.g., "Cyberpunk Nights").
*   **Automated Hashtag Generation:** Adding a step to generate relevant hashtags based on the image content and caption.
*   **A/B Testing:** Experimenting with different prompts or models to optimize caption engagement.

## 8. Implementation Tickets

### Ticket Dependency Tree

*   **Standalone Tickets (Can be worked on in parallel):**
    *   [timlawrenz/fluffy-train#52](https://github.com/timlawrenz/fluffy-train/issues/52): [Database] Add caption column to photo_analyses table
    *   [timlawrenz/fluffy-train#53](https://github.com/timlawrenz/fluffy-train/issues/53): [Backend] Extend OllamaClient with generate_caption method

*   **Dependent Tickets:**
    *   [timlawrenz/fluffy-train#54](https://github.com/timlawrenz/fluffy-train/issues/54): [Backend] Update CuratorsChoice to use generated captions
        *   **Depends on:** #52
    *   [timlawrenz/fluffy-train#55](https://github.com/timlawrenz/fluffy-train/issues/55): [Backend] Create Photos::Analyse::Caption command
        *   **Depends on:** #52, #53
    *   [timlawrenz/fluffy-train#56](https://github.com/timlawrenz/fluffy-train/issues/56): [Backend] Integrate Caption command into AnalysePhoto chain
        *   **Depends on:** #55