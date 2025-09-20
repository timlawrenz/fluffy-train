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

## Milestone 3: Basic Content Selection with Embeddings

### Goal
Introduce intelligent, automated content selection based on image embeddings. This moves the application from a manual tool to a basic automation engine, capable of curating a content calendar based on predefined strategies.

### Key Features
- **Thematic Clustering**: Implement a feature to group images into visual themes using DINO embeddings.
- **Text-Based Search**: Use CLIP embeddings to allow users to select images based on a text prompt (e.g., "a feeling of adventure").
- **Similarity Search**: Given a selected image, find the top N most visually similar images using DINO embeddings.
- **Content Strategy Implementation**: Create simple, selectable posting strategies, such as "Theme of the Week" (posting from a single cluster) or "Thematic Rotation" (posting from a different cluster each day).

### Success Metrics
- The system can automatically cluster the image library into at least 5 distinct, visually coherent themes.
- A user can provide a text prompt and get a list of the top 10 relevant images with at least 80% accuracy (subjectively measured).
- The application can automatically select and queue an image based on a chosen content strategy for 7 consecutive days without manual intervention.

## Milestone 4: Generative AI for Captions and Content Adaptation

### Goal
Leverage generative AI to automate the creative aspects of posting, such as caption writing and image formatting, tailored to a specific brand persona. This milestone aims to make the entire content creation and scheduling process almost fully autonomous and on-brand.

### Key Features
- **Configurable Persona Definition**: Allow the user to define a detailed persona, including personality traits (e.g., witty, professional, adventurous), age, gender, and brand voice guidelines.
- **Persona-Driven Caption Generation**: Use a model like BLIP or Git, guided by the defined persona, to generate relevant, on-brand captions, titles, and tags for a selected image.
- **Image Adaptation (Outpainting)**: Implement a feature to automatically adapt image formats (e.g., extending a horizontal photo to a 4:5 vertical format for Instagram) using outpainting techniques.
- **Caption Strategy**: Allow users to provide a high-level instruction for the caption, such as "make it witty" or "ask a question to engage the audience," which will be interpreted within the context of the defined persona.

### Success Metrics
- A user can define and save at least three distinct personas.
- For any given image, the system can generate 3 distinct caption options that are contextually relevant and consistent with the selected persona's voice.
- When switching between personas, the generated captions for the same image show a clear and appropriate shift in tone, style, and vocabulary.
- The generated captions require minimal to no editing for at least 80% of the images.
- The system can successfully convert a landscape-oriented image into a portrait-oriented one without cropping the original content, and the result is visually coherent.

## Milestone 5: The Generative Feedback Loop

### Goal
Create a self-optimizing content engine by establishing a feedback loop between post-performance and new content generation. This is the most advanced stage, where the system learns from audience engagement to create more successful content over time.

### Key Features
- **Performance Data Collection**: Integrate with the Instagram (or Buffer) API to collect engagement metrics (likes, comments, shares) for each post.
- **Success Score Calculation**: Develop an algorithm to calculate a weighted "Success Score" for each post based on its performance data.
- **Patch-Level Embedding Analysis**: For top-performing posts, extract patch-level embeddings (e.g., from DINOv2) to identify successful micro-features.
- **Feature-to-Text Translation**: Use a multi-modal model to translate the successful visual micro-features into textual descriptions.
- **Optimized Prompt Synthesis**: Automatically combine the textual descriptions of successful features to generate new, optimized prompts for an image generation model (e.g., FLUX).

### Success Metrics
- The system can successfully retrieve and store engagement data for all posts it schedules.
- The system can identify the top 10% of performing posts based on the calculated Success Score.
- The system can generate a list of at least 20 textual concepts (e.g., "curly blonde hair," "bokeh background") that are statistically correlated with high engagement.
- The system can automatically generate a new, optimized prompt that, when used to generate a new batch of images, results in a 10% higher average Success Score compared to the previous batch.