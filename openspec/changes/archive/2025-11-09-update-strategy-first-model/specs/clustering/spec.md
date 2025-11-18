# Clustering Spec Delta

**Change ID**: `update-strategy-first-model`  
**Affects**: clustering

---

## MODIFIED Requirements

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

## ADDED Requirements

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
