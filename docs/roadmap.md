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

​Goal: Transform fluffy-train from a manual analysis tool into a true automation engine. This milestone establishes the core functionality of posting on a regular schedule without any daily human intervention.

### ​Key Features:
​Direct Instagram API Integration: Replace the Buffer API with a robust integration to post images and captions directly to a specified Instagram account.
​Automated Scheduler: Implement a cron job or similar scheduling system that runs the posting script automatically at a user-defined time and frequency (e.g., daily at 9:00 AM).
​Basic Posting Strategy - "Curator's Choice": The default strategy will automatically select a single image for posting based on a simple rule: "Post the highest-rated, not-yet-posted image from the library," using the aesthetic and quality scores from Milestone 2.
​Posting History Log: Create a simple database or log file to track which images have been posted to avoid duplicates.

### ​Acceptance Criteria:
​The application can successfully post an image and a predefined caption to Instagram on a set schedule.
​The scheduler runs reliably for 3 consecutive days without manual intervention.
​The system correctly selects the highest-scoring available image and marks it as "posted" in its log to prevent reuse.

##​ Milestone 4: Narrative Curation via Thematic Clustering

​Goal: Introduce intelligent content curation. Instead of just posting the "best" photo, this milestone enables the application to tell stories and build a cohesive feed aesthetic by grouping images into visual themes.

### ​Key Features:
​Visual Theme Clustering: Integrate a script that uses DINO embeddings to analyze the entire "usable" photo library and group images into distinct visual clusters (e.g., "Cyberpunk Nights," "Forest Wanderer," "Beach Days").
​Cluster Management UI: A simple interface (CLI is fine) to view the clusters, see the images within them, and give them descriptive names.
​Content Strategy Engine: Develop a system to execute predefined posting strategies.
​Strategy 1: "Theme of the Week": Post exclusively from a single named cluster for 7 days.
​Strategy 2: "Thematic Rotation": Post one image from a different cluster each day to maximize variety.

### ​Acceptance Criteria:
​The system can automatically cluster a library of 1,000+ images into at least 10 visually coherent groups.
​A user can successfully run the "Theme of the Week" strategy, and for 7 days, the application correctly posts images only from the selected cluster.
​A user can switch to the "Thematic Rotation" strategy, and the system posts from a different cluster each day.

## ​Milestone 5: Generative AI for Persona-Driven Storytelling
​Goal: Automate the creative writing process. This milestone leverages generative AI to create compelling, on-brand captions that align with the fictional model's persona and the visual theme of the post.

### ​Key Features:
​Configurable Persona Engine: Allow a user to define a persona for the fictional model in a configuration file, including key traits, tone of voice, and common topics.
​Context-Aware Caption Generation: The system will generate captions based on multiple inputs:
​The image itself.
​The name of the visual cluster it belongs to (from Milestone 4).
​The defined persona.
​Hashtag and Tag Generation: Automatically suggest relevant hashtags based on the cluster name and image content.

### ​Acceptance Criteria:
​For any given image, the system generates a caption that is relevant to both the image content and the name of its cluster (e.g., a "Cyberpunk" image gets a futuristic caption).
​The generated captions clearly reflect the tone and traits defined in the persona file.
​The system automatically appends at least 5 relevant hashtags to the generated caption.
​The entire process from image selection to caption generation to posting can run fully autonomously.

## ​Milestone 6: The Generative Feedback Loop & Self-Optimization
​Goal: Create a self-improving content engine. This final milestone closes the loop by allowing audience engagement to directly influence the creation of new, optimized images.

### ​Key Features:
​Performance Data Scraper: A script to periodically scrape engagement metrics (likes, comments) for each post made by the application.
​Success Score Algorithm: Calculate a weighted "Success Score" for each post to identify top performers.
​Patch-Level Feature Analysis: For the top 10% of posts, extract patch-level DINO embeddings to identify recurring successful micro-features (e.g., a specific hairstyle, background texture, clothing style).
​Feature-to-Prompt Synthesis: A system to translate these successful visual features into textual concepts.
​Optimized Prompt Generation: Automatically combine the most successful concepts to generate new, high-potential prompts for the FLUX image generation model.

### ​Acceptance Criteria:
​The system can retrieve and store engagement data for all its posts.
​The system can rank all past posts by their Success Score and identify the top performers.
​The system can output a list of at least 10 textual concepts (e.g., "curly hair," "leather jacket," "rainy street") that are statistically correlated with high engagement.
​The system can successfully generate a new, fully-formed prompt ready for use in the FLUX model, representing a "greatest hits" combination of successful elements.