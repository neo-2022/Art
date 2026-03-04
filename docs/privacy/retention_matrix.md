# Retention matrix

| type | retention | storage | deletion | owner_component |
|---|---|---|---|---|
| events | 30 days | sqlite | hard delete | core/storage |
| incidents | 180 days | sqlite | hard delete | core/incidents |
| audit | 365 days | sqlite | hard delete | core/audit |
| attachments | 30 days | blob/local | hard delete | core/attachments |
