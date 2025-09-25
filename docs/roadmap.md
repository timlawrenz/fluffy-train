# fluffy-train: Product Roadmap

This document outlines the development roadmap for `fluffy-train`, a project designed to automate and optimize Instagram content posting using machine learning and generative AI. The roadmap is divided into distinct milestones, each delivering a complete, valuable feature that builds upon the previous one.

## Milestone 1: Foundational Setup & Manual Scheduling

### Goal
Establish the core infrastructure for the application. The primary objective is to enable a user to manually select a pre-processed image from the library and schedule it for posting to Instagram via the Buffer API. This milestone focuses on setting up the essential pipeline and user interaction.

### Key Features
- **Image Library Ingestion**: Script to scan a directory of images, generate CLIP and DINO embeddings, and store them in a searchable database (e.g., a vector database or a simple file-based index).
- **Basic User Interface (CLI or simple Web UI)**: An interface to view images from the library.
- **Manual Selection**: Allow the user to select a specific image from the library.
- **Buffer API Integration**: Connect to the Buffer API to schedule the selected image for posting. The user will manually provide the caption.

### Success Metrics
- A user can successfully ingest a folder of at least 100 images.
- A user can view the ingested images.
- A user can select an image and successfully queue it to a Buffer account.
- The scheduled post appears correctly in the Buffer queue.

## Milestone 2: Advanced Photo Analysis & Quality Control

### Goal
Automate the quality control process by integrating advanced image analysis techniques. This ensures that only high-quality, aesthetically pleasing images are selected for posting, reducing the need for manual curation.

### Key Features
- **Technical Quality Filters**:
    - **Blur & Sharpness Detection**: Automatically calculate a sharpness score for each image and filter out blurry photos.
    - **Exposure & Contrast Analysis**: Analyze image histograms to filter out over or underexposed photos.
- **Aesthetic Scoring**: Integrate a pre-trained aesthetic scoring model (e.g., based on the AVA dataset) to rate the visual appeal of each image.
- **Content-Aware Filtering**:
    - **Object Detection**: Use a model like YOLO to identify and filter images based on the presence or absence of specific objects.
    - **Face Detection**: Detect human faces and filter based on attributes like eye closure.

### Success Metrics
- The system can process the entire image library and assign a quality score (combining technical and aesthetic metrics) to each image.
- When running a content selection strategy, the system automatically rejects at least 95% of images that a human would deem low-quality (blurry, poorly exposed).
- A user can define a rule like "only post images with an aesthetic score above 7/10" and the system correctly adheres to it.
- A user can successfully filter the library for "all photos containing a bicycle."

## Milestone 3: Automated Posting Engine & Basic Scheduling

Goal: Transform fluffy-train from a manual analysis tool into a true automation engine. This milestone establishes the core functionality of posting on a regular schedule without any daily human intervention.

### Key Features:
Automated Scheduler: Implement a cron job or similar scheduling system that runs the posting script automatically at a user-defined time and frequency (e.g., daily at 9:00 AM).
Basic Posting Strategy - "Curator's Choice": The default strategy will automatically select a single image for posting based on a simple rule: "Post the highest-rated, not-yet-posted image from the library," using the aesthetic and quality scores from Milestone 2.
Posting History Log: Create a simple database or log file to track which images have been posted to avoid duplicates.

### Acceptance Criteria:
The application can successfully post an image and a predefined caption to Instagram on a set schedule.
The scheduler runs reliably for 3 consecutive days without manual intervention.
The system correctly selects the highest-scoring available image and marks it as "posted" in its log to prevent reuse.

## Milestone 4a: Core Clustering Engine

Goal: Implement the foundational unsupervised machine learning task. This milestone focuses purely on using DINO embeddings to analyze the photo library and group images into distinct visual clusters based on their thematic content.

### Key Features:
- **Clustering Script**: An automated script that processes the entire "usable" photo library.
- **Embedding Analysis**: Applies a clustering algorithm (e.g., K-Means, DBSCAN) to the DINO embeddings of the images.
- **Persistent Storage**: Saves the resulting cluster assignments for each photo back to the database.

### Acceptance Criteria:
- The script can process a library of 1,000+ images and assign a cluster ID to each one without errors.
- The resulting cluster assignments are saved persistently in the database.
- A visual inspection of 5 different clusters shows that the images within each cluster are thematically and aesthetically similar.

## Milestone 4b: Cluster Management & Curation

Goal: Build the essential human-in-the-loop component for curation. This milestone provides the tools to review, name, and refine the automatically generated clusters, turning raw ML output into meaningful, usable themes.

### Key Features:
- **Cluster Viewing Interface**: A CLI or simple web UI to list all generated clusters and see the number of images in each.
- **Image Sampling**: An interface to view a random sample of images from any selected cluster to understand its theme.
- **Curation Tools**: Functionality to assign a human-readable name to a cluster (e.g., "Cyberpunk Nights") and to mark a cluster as "unusable" to exclude it from posting strategies.

### Acceptance Criteria:
- A user can successfully list all clusters and see a count of their images.
- A user can view at least 10 sample images from any selected cluster.
- A user can assign a name to a cluster, and this name is correctly saved and associated with the cluster ID.
- A user can mark a cluster as "unusable," and it will be ignored by the content strategy engine.

## Milestone 4c: Content Strategy Engine

Goal: Activate the curated themes by implementing the logic for automated posting strategies. This milestone allows the application to tell stories over time by intelligently selecting from the named clusters.

### Key Features:
- **Strategy Executor**: A system that can run predefined, multi-day posting strategies.
- **Strategy 1: "Theme of the Week"**: A strategy that posts exclusively from a single, user-selected named cluster for a defined period (e.g., 7 days).
- **Strategy 2: "Thematic Rotation"**: A strategy that posts one image from a different named cluster each day to maximize variety.

### Acceptance Criteria:
- A user can select the "Theme of the Week" strategy and a named cluster, and the system correctly posts images *only* from that cluster for 7 consecutive days.
- A user can switch to the "Thematic Rotation" strategy, and the system correctly posts from a different named cluster each day, successfully cycling through all available curated clusters.
- The system correctly logs which cluster and which strategy were used for each post.

## Milestone 5a: Persona-Driven Caption Generation

Goal: Automate the core creative writing task. This milestone focuses on generating context-aware, on-brand captions using a configurable persona and the thematic context from the image's cluster.

### Key Features:
- **Configurable Persona Engine**: A simple configuration file (e.g., YAML) where a user can define a persona's key traits, tone of voice, and common topics.
- **Context-Aware Prompting**: A script that generates a prompt for a generative AI model, including inputs like the image's cluster name and the defined persona.
- **Generative AI Integration**: Connects to a generative AI model (e.g., via an API) to produce a caption based on the generated prompt.

### Acceptance Criteria:
- Given an image from the "Forest Wanderer" cluster, the system generates a caption that is thematically relevant to nature, exploration, or solitude.
- The generated captions consistently reflect the tone (e.g., "witty," "inspirational," "mysterious") defined in the persona file across at least 10 different test images.
- The caption generation process can be successfully and repeatedly run for any image in the curated library.

## Milestone 5b: Automated Hashtag & Tag Generation

Goal: Enhance the generated caption with relevant metadata to increase reach and engagement. This milestone automates the creation of hashtags and tags based on the image's theme.

### Key Features:
- **Hashtag Generation Module**: A system that suggests relevant hashtags based on the image's cluster name.
- **Content-Based Hashtags (Stretch Goal)**: Analyze image content to suggest more specific, secondary hashtags.

### Acceptance Criteria:
- The system automatically appends at least 5 relevant hashtags to each generated caption.
- For an image in the "Cyberpunk Nights" cluster, generated hashtags include terms like #cyberpunk, #neocity, #futuristic, etc.
- The generated hashtags are appended in a clean, readable format to the main caption.

## Milestone 5c: Full Automation & Integration

Goal: Combine the content strategy engine with the generative AI components to create a fully autonomous posting pipeline. This final integration step allows the system to run end-to-end without any manual intervention.

### Key Features:
- **Pipeline Integration**: The caption and hashtag generation modules (5a, 5b) are integrated into the automated posting scheduler from Milestone 4c.
- **End-to-End Automation**: The entire process, from thematic image selection to creative writing to scheduling via the Buffer API, runs on a predefined schedule.

### Acceptance Criteria:
- The application can run fully autonomously for 3 consecutive days, each day correctly selecting an image based on the active strategy, generating a persona-driven caption with hashtags, and scheduling it via the Buffer API.
- The final post content scheduled in Buffer correctly contains the selected image, a thematically appropriate caption, and relevant hashtags.
- The system correctly logs all key steps of the fully automated process, from selection to generation to scheduling.

## Milestone 6: The Generative Feedback Loop & Self-Optimization
Goal: Create a self-improving content engine. This final milestone closes the loop by allowing audience engagement to directly influence the creation of new, optimized images.

### Key Features:
Performance Data Scraper: A script to periodically scrape engagement metrics (likes, comments) for each post made by the application.
Success Score Algorithm: Calculate a weighted "Success Score" for each post to identify top performers.
Patch-Level Feature Analysis: For the top 10% of posts, extract patch-level DINO embeddings to identify recurring successful micro-features (e.g., a specific hairstyle, background texture, clothing style).
Feature-to-Prompt Synthesis: A system to translate these successful visual features into textual concepts.
Optimized Prompt Generation: Automatically combine the most successful concepts to generate new, high-potential prompts for the FLUX image generation model.

### Acceptance Criteria:
The system can retrieve and store engagement data for all its posts.
The system can rank all past posts by their Success Score and identify the top performers.
The system can output a list of at least 10 textual concepts (e.g., "curly hair," "leather jacket," "rainy street") that are statistically correlated with high engagement.
The system can successfully generate a new, fully-formed prompt ready for use in the FLUX model, representing a "greatest hits" combination of successful elements.
