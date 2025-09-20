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
