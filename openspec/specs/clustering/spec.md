# clustering Specification

## Purpose
TBD - created by archiving change make-clusters-persona-specific. Update Purpose after archive.
## Requirements
### Requirement: Persona-Scoped Cluster Management

The system SHALL ensure all clusters are owned by exactly one persona and cannot be shared across personas. Clusters MAY be created manually or through optional automated clustering services.

**Legacy Note**: Automated clustering (K-means) is available as a legacy tool for organizing existing photo batches, but manual cluster creation is the primary workflow.

#### Scenario: Create cluster manually with persona ownership

- **GIVEN** a persona exists
- **WHEN** creating a cluster manually
- **THEN** the cluster SHALL have persona_id assigned
- **AND** the persona_id SHALL reference the persona
- **AND** cluster creation without persona_id SHALL fail validation

#### Scenario: Create cluster with AI prompt

- **GIVEN** a persona exists
- **AND** an AI-generated prompt exists
- **WHEN** creating a cluster with ai_prompt field
- **THEN** the cluster SHALL be created with persona ownership
- **AND** the ai_prompt field SHALL store the generation prompt
- **AND** the cluster can be linked to a pillar

#### Scenario: Query clusters by persona

- **GIVEN** Sarah has 3 clusters
- **AND** TechReviewer has 2 clusters
- **WHEN** querying clusters for Sarah
- **THEN** only Sarah's 3 clusters SHALL be returned
- **AND** TechReviewer's clusters SHALL NOT be included
- **AND** the query SHALL use persona_id index for performance

---

### Requirement: Cluster-Photo Persona Consistency

The system SHALL ensure photos within a cluster belong to the same persona that owns the cluster.

#### Scenario: Validate photo-cluster persona match

- **GIVEN** Sarah owns a cluster "Beach Photos"
- **AND** a photo belongs to Sarah
- **WHEN** assigning the photo to "Beach Photos" cluster
- **THEN** the assignment SHALL succeed
- **AND** the photo's persona_id matches cluster's persona_id

#### Scenario: Reject cross-persona photo assignment

- **GIVEN** Sarah owns a cluster "Beach Photos"
- **AND** a photo belongs to TechReviewer
- **WHEN** attempting to assign TechReviewer's photo to Sarah's cluster
- **THEN** the assignment SHALL fail
- **AND** return validation error
- **AND** the cluster remains unchanged

#### Scenario: Clustering service respects persona boundaries

- **GIVEN** photos from multiple personas exist
- **WHEN** running clustering service for Sarah
- **THEN** only Sarah's photos SHALL be clustered
- **AND** all resulting clusters SHALL have Sarah's persona_id
- **AND** no photos from other personas SHALL be included

---

### Requirement: Cluster Lifecycle Management

The system SHALL manage cluster lifecycle in relation to persona ownership.

#### Scenario: Delete persona with clusters

- **GIVEN** Sarah has 5 clusters
- **AND** clusters contain photos
- **WHEN** attempting to delete Sarah's persona
- **THEN** the system SHALL prevent deletion (or cascade delete based on configuration)
- **AND** return error indicating dependent clusters exist
- **AND** require explicit cluster cleanup before persona deletion

#### Scenario: Orphaned cluster prevention

- **GIVEN** a cluster exists in the database
- **WHEN** validating database integrity
- **THEN** every cluster SHALL have a valid persona_id
- **AND** persona_id SHALL reference an existing persona
- **AND** foreign key constraint SHALL enforce this relationship

#### Scenario: Cluster ownership is immutable

- **GIVEN** a cluster owned by Sarah
- **WHEN** attempting to change persona_id to TechReviewer
- **THEN** the system SHALL prevent the change
- **AND** return validation error
- **AND** cluster ownership remains unchanged

---

### Requirement: Efficient Persona-Scoped Queries

The system SHALL provide efficient database queries for persona-scoped cluster operations.

#### Scenario: List persona's clusters with index

- **GIVEN** 10,000 total clusters across all personas
- **AND** Sarah has 50 clusters
- **WHEN** querying for Sarah's clusters
- **THEN** the query SHALL use persona_id index
- **AND** return only Sarah's 50 clusters
- **AND** query execution time SHALL be < 50ms

#### Scenario: Count unposted photos per persona's clusters

- **GIVEN** Sarah has 3 clusters with unposted photos
- **WHEN** content strategy queries available clusters
- **THEN** the query SHALL use `persona.clusters` relationship
- **AND** avoid unnecessary joins through photos table for persona filtering
- **AND** return clusters with accurate unposted photo counts

---

### Requirement: Migration and Data Integrity

The system SHALL handle migration of existing global clusters to persona-scoped model with data integrity.

#### Scenario: Backfill existing clusters with persona_id

- **GIVEN** existing clusters without persona_id
- **WHEN** running backfill migration
- **THEN** each cluster SHALL be assigned persona_id based on its photos
- **AND** clusters with majority photos from Sarah SHALL get Sarah's persona_id
- **AND** clusters with no photos SHALL be handled according to policy (delete or assign default)

#### Scenario: Handle mixed-persona clusters during migration

- **GIVEN** a cluster with 60% Sarah's photos and 40% TechReviewer's photos
- **WHEN** running backfill migration
- **THEN** cluster SHALL be assigned to Sarah (majority)
- **AND** TechReviewer's photos SHALL be reassigned to appropriate cluster or flagged
- **AND** migration log SHALL record split decision

#### Scenario: Enforce NOT NULL constraint after backfill

- **GIVEN** all clusters have been assigned persona_id
- **WHEN** applying NOT NULL constraint
- **THEN** constraint SHALL succeed without errors
- **AND** future cluster creation SHALL require persona_id
- **AND** database integrity SHALL be enforced at schema level

### Requirement: Manual Cluster Creation

The system SHALL support manual cluster creation as the primary workflow for organizing content.

#### Scenario: Create empty cluster for planned content

- **GIVEN** a persona has a content pillar with a gap
- **WHEN** creating a cluster manually
- **THEN** the cluster SHALL be created with a descriptive name
- **AND** the cluster SHALL have no photos initially
- **AND** photos can be added later through import workflow

#### Scenario: Create cluster from AI suggestion

- **GIVEN** an AI content prompt has been generated
- **WHEN** creating a cluster from the AI suggestion
- **THEN** the cluster SHALL be created with ai_prompt field populated
- **AND** the cluster name SHALL reflect the prompt's scene/theme
- **AND** the cluster SHALL be automatically linked to the originating pillar

---

### Requirement: Legacy Automated Clustering (Optional)

The system SHALL provide automated clustering for organizing existing large photo batches using K-means algorithm when explicitly requested.

**Note**: This is a legacy feature. The primary workflow is manual cluster creation based on strategic content planning.

#### Scenario: Run K-means clustering on unclustered photos

- **GIVEN** a persona has 100+ unclustered photos with embeddings
- **WHEN** running the clustering service
- **THEN** photos SHALL be grouped into K clusters using K-means
- **AND** clusters SHALL be created with generic names
- **AND** persona_id SHALL be assigned to all clusters

#### Scenario: Skip automated clustering when not needed

- **GIVEN** content is managed through strategic planning
- **WHEN** all clusters are manually created
- **THEN** the automated clustering service SHALL NOT be required
- **AND** the system SHALL function fully without running clustering

