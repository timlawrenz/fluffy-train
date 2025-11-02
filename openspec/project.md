# Project Context

## Purpose
`fluffy-train` is an automated Instagram content posting system that uses machine learning and generative AI to optimize social media engagement. The application manages photo libraries, analyzes image quality and aesthetics, generates intelligent captions, and automatically schedules posts based on configurable content strategies.

**Core Goals:**
- Automate the end-to-end Instagram posting workflow
- Use ML-based image embeddings (CLIP, DINO) for content analysis and clustering
- Generate persona-driven captions and hashtags using generative AI
- Create a self-improving content engine through engagement feedback loops
- Enable thematic posting strategies (e.g., "Theme of the Week", "Thematic Rotation")

## Tech Stack

### Backend Framework
- **Ruby 3.4.5**
- **Rails 8.0** (Ruby on Rails web framework)
- **PostgreSQL** (primary database with pgvector extension for vector embeddings)

### Key Ruby Gems
- **gl_command** - Business logic command pattern implementation
- **packs-rails** / **packwerk** - Modular pack-based architecture
- **state_machines-activerecord** - State machine management for models
- **neighbor** - Vector similarity search
- **rumale** - Machine learning library for clustering
- **devise** - User authentication
- **doorkeeper** - OAuth2 provider
- **pundit** - Authorization framework
- **solid_queue** - Background job processing
- **faraday** - HTTP client for API integrations

### Storage & Assets
- **ActiveStorage** with **aws-sdk-s3** - Cloud storage (S3-compatible providers like Backblaze B2)
- **ruby-vips** - Image processing

### Frontend
- **Tailwind CSS v4** - Modern utility-first CSS framework
- **ViewComponents** - Reusable UI components
- **Turbo Rails** - Hotwire for SPA-like interactions
- **Stimulus** - JavaScript framework
- **Haml** - Template engine

### Testing & Quality
- **RSpec** - Testing framework
- **FactoryBot** - Test data factories
- **Capybara** - Feature/integration testing
- **WebMock** - HTTP request stubbing
- **Brakeman** - Security vulnerability scanner
- **RuboCop** - Code linter and formatter
- **SimpleCov** - Code coverage
- **Reek** - Code smell detector

### External APIs
- **Instagram Graph API** (Meta) - For posting content to Instagram
- **Buffer API** (deprecated, being replaced by Instagram Graph API)

## Project Conventions

### Code Style
- Follow standard Ruby and Rails conventions
- Use RuboCop for code linting and formatting
- Class and method names should be descriptive and follow Ruby naming conventions
- Minimal comments - only for clarification where needed
- Use string frozen_string_literal: true pragma in all Ruby files

### Architecture Patterns

#### Pack-Based Architecture (Packwerk)
The application is organized into domain-specific packs located in `packs/` subfolder:

**Core Packs:**
- **`packs/personas`** - Manages social media personas (distinct online identities)
- **`packs/photos`** - Manages photo storage, metadata, embeddings, and bulk imports
- **`packs/scheduling`** - Handles content scheduling, posting, and social media API integration

**Pack Principles:**
1. **High Encapsulation** - Packs hide internal implementation details (models, services, commands)
2. **Explicit Public API** - All inter-pack interaction goes through `app/public/` directory
3. **No Leaky Abstractions** - Public APIs must not return `ActiveRecord::Relation` objects; return arrays, POROs, or pack models
4. **Declared Dependencies** - Dependencies must be declared in `package.yml`

#### Command Pattern (GLCommand)
- **Business Logic Isolation** - Use `GLCommand` gem for all business logic
- **Command Naming** - Must start with a verb (e.g., `CreateUser`, `SendEmail`)
- **Single Responsibility** - Each command has one small, focused purpose
- **Chaining** - Combine commands into chains for complex multi-step operations
- **Rollback Support** - Commands implement `rollback` methods for automatic failure recovery
- **Automatic Rollback** - Failed commands trigger rollback of all previously executed commands in reverse order

#### State Management
- Use `state_machines-activerecord` gem for any model with state transitions
- Status columns must be string type
- Define clear states, events, and transitions

#### Controller Responsibilities
- Focus on authentication (using Pundit)
- Input validation
- Calling GLCommand
- Handling command results
- **Avoid domain logic in controllers** - delegate to GLCommands

### Testing Strategy

#### Unit Tests
- Cover all classes, methods, and GLCommands with isolated unit tests
- Mock database and external calls where possible and reasonable
- **Test rollback logic** for all commands that implement it
- Use GLCommand's built-in RSpec matchers for declarative testing
- Use `build_context` method when stubbing command responses

#### Request Specs
- Test authentication (Pundit)
- Verify correct GLCommand is called with correct arguments
- Assert HTTP response
- No mocks/stubs in request specs

#### Integration Specs
- Limited to critical end-to-end business flows only
- Full-stack tests hitting the database
- No mocks/stubs

#### Specific Requirements
- **No controller specs** - use request specs instead
- **N+1 query prevention** - implement tests using `n_plus_one_control`
- **FactoryBot** - Use for test data setup (no short notation - use `FactoryBot.create`)
- Factories defined in `spec/factories/` with standard naming

#### ViewComponents
- Every component must have a corresponding preview file in `spec/components/previews/`

### Database & Migrations
- **Schema-only migrations** - Migrations contain only schema changes
- **Separate Rake tasks** - Use for data backfills/manipulation
- **Multi-phase column changes** - Follow safe deployment process:
  1. Add Column
  2. Write Code
  3. Backfill Task
  4. Add Constraint
  5. Read Code
  6. Drop Old Column

### Git Workflow
- Follow standard Git best practices
- Atomic, focused commits
- Clear commit messages describing the change

## Domain Context

### Core Domain Models
- **Persona** - A distinct social media identity for posting content
- **Photo** - Image files with associated metadata, embeddings, and quality scores
- **PhotoAnalysis** - Quality metrics (blur, exposure, aesthetic scores) for photos
- **Post** - Scheduled or published content linking a photo to a persona
- **Cluster** - Thematic groupings of photos based on visual similarity (DINO embeddings)

### ML & AI Components
- **Image Embeddings** - CLIP and DINO embeddings for semantic and visual analysis
- **Clustering** - K-Means/DBSCAN for grouping similar images
- **Quality Analysis** - Blur detection, exposure analysis, aesthetic scoring
- **Caption Generation** - Persona-driven captions using generative AI
- **Hashtag Generation** - Automated hashtag suggestions based on themes

### Content Strategy Engine
- **Curator's Choice** - Posts highest-rated, unposted image
- **Theme of the Week** - Posts from a single cluster for defined period
- **Thematic Rotation** - Cycles through different clusters daily

### Workflow Phases
1. **Photo Ingestion** - Bulk import from filesystem
2. **Analysis** - Generate embeddings and quality scores
3. **Clustering** - Group photos by visual themes
4. **Curation** - Human-in-the-loop cluster naming and filtering
5. **Strategy Execution** - Automated content selection
6. **Caption Generation** - AI-driven caption and hashtag creation
7. **Scheduling** - Queue content for posting
8. **Posting** - Publish to Instagram via API
9. **Feedback Loop** - Analyze engagement to optimize future content

## Important Constraints

### Technical Constraints
- Photos stored locally and uploaded to cloud storage (S3-compatible) for permanent URLs
- Instagram Graph API requires public, permanent URLs for images
- Long-lived access tokens required for Instagram API
- Vector embeddings require PostgreSQL with pgvector extension
- Background jobs processed via Solid Queue

### Security & Privacy
- Credentials stored in encrypted Rails credentials (`config/credentials.yml.enc`)
- No secrets in source code
- Use `.env` files for development configuration

### Performance
- Implement N+1 query prevention
- Optimize vector similarity searches
- Consider batch processing for large photo libraries

## External Dependencies

### Required External Services
1. **Instagram Graph API (Meta)**
   - Purpose: Publishing content to Instagram
   - Requirements: Meta Developer Account, Instagram Business/Creator Account linked to Facebook Page
   - Credentials: App ID, App Secret, Long-lived Access Token, Instagram Account ID
   - Required permissions: `instagram_content_publish`, `pages_show_list`, `instagram_basic`, `pages_read_engagement`

2. **S3-Compatible Cloud Storage** (e.g., Amazon S3, Backblaze B2)
   - Purpose: ActiveStorage backend for public, permanent image URLs
   - Requirements: Bucket with public read access
   - Credentials: Access Key ID, Secret Access Key

3. **Generative AI Service** (future milestone)
   - Purpose: Caption and hashtag generation
   - Implementation TBD

### Optional External Services
- **Image Embedding Service** - External service for generating CLIP/DINO embeddings
- **Error Tracking** (e.g., Sentry) - Configured via sentry-rails/sentry-ruby gems
- **Scheduler** (e.g., Heroku Scheduler) - For automated posting in production
