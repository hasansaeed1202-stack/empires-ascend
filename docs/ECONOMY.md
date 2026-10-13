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

`ResourceStore` initializes these six stable identifiers at zero and exposes a
read-only snapshot. A later approved milestone should define production sources,
sinks, transactions, ownership namespaces, and tuning in data resources without
coupling them to the HUD.
