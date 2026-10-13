# Six-resource economy plan

Milestone 1 defines vocabulary and storage boundaries only. It does not implement
production, gathering, costs, conversion, or balancing.

| Resource | Planned strategic role |
| --- | --- |
| Provisions | Sustains population and near-term operations. |
| Materials | Represents raw construction and manufacturing inputs. |
| Craftsmanship | Represents skilled fabrication and quality output. |
| Knowledge | Supports discovery, administration, and technical development. |
| Influence | Represents political, cultural, and diplomatic reach. |
| Logistics | Represents transport, supply capacity, and operational reach. |

Each resource is defined by a `ResourceDefinition` in `resources/economy/`.
Player balances start at 350 Provisions, 300 Materials, 30 Craftsmanship,
0 Knowledge, 25 Influence, and 20 Logistics. AI balances start at zero. Every
balance is an integer between 0 and 2,000 inclusive.

`ResourceStore` owns isolated entity inventories. Its `add`, `subtract`,
`set_amount`, `try_consume`, and `try_transaction` methods are the write boundary.
Multi-resource transactions validate all resulting balances before applying any
change. Production, gathering, and gameplay costs remain deferred.

HUD code reads `snapshot(entity)` or `get_amount(resource, entity)`. Snapshots are
deep copies, so consumers cannot mutate store state. Consumers may subscribe to
`resource_changed` for individual changes or `resources_changed` for atomic old
and new snapshots; UI code must not reach into store internals.
