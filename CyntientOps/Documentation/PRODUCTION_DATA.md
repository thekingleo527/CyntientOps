**Production Data Inventory**

This inventory reflects the current portfolio, workers, clients, and buildings wired in code and seeders.

**Workers**

- IDs and names (from `CanonicalIDs.Workers.nameMap`):
  - `1`: Greg Hutson
  - `2`: Edwin Lema
  - `4`: Kevin Dutan
  - `5`: Mercedes Inamagua
  - `6`: Luis Lopez
  - `7`: Angel Guirachocha
  - `8`: Shawn Magloire

Notes:
- Roles are managed via user records; see `CoreTypes.UserRole` and auth service.

**Clients**

- Source: `Services/Database/ClientBuildingSeeder.swift`
- Active clients and building assignments:
  - JM Realty (`JMR`): buildings `3,5,6,7,9,10,11,14,21` (9 total)
  - Weber Farhat Realty (`WFR`): `13` (1)
  - Solar One (`SOL`): `16` (1)
  - Grand Elizabeth LLC (`GEL`): `8` (1)
  - Citadel Realty (`CIT`): `4,18` (2)
  - Corbel Property (`COR`): `15` (1)

Filtering expectations (validated in `ProductionReadinessChecker`):
- JM Realty sees 9 buildings; Weber Farhat sees 1.

**Buildings**

- Canonical IDs and names (from `CanonicalIDs.Buildings.nameMap`):
  - `1`: 12 West 18th Street
  - `3`: 135-139 West 17th Street
  - `4`: 104 Franklin Street
  - `5`: 138 West 17th Street
  - `6`: 68 Perry Street
  - `7`: 112 West 18th Street
  - `8`: 41 Elizabeth Street
  - `9`: 117 West 17th Street
  - `10`: 131 Perry Street
  - `11`: 123 1st Avenue
  - `13`: 136 West 17th Street
  - `14`: Rubin Museum (142–148 W 17th)
  - `15`: 133 East 15th Street
  - `16`: Stuyvesant Cove Park
  - `17`: 178 Spring Street
  - `18`: 36 Walker Street
  - `19`: 115 7th Avenue
  - `20`: CyntientOps HQ
  - `21`: 148 Chambers Street

Removed:
- `2`: 29–31 East 20th Street (no longer in portfolio)

Addresses and coordinates (from seeder `buildingData`):
- `1`  12 West 18th Street, New York, NY 10011  (40.7387, -73.9941)
- `3`  135-139 West 17th Street, New York, NY 10011  (40.7406, -73.9974)
- `4`  104 Franklin Street, New York, NY 10013  (40.7197, -74.0079)
- `5`  138 West 17th Street, New York, NY 10011  (40.7407, -73.9976)
- `6`  68 Perry Street, New York, NY 10014  (40.7351, -74.0063)
- `7`  112 West 18th Street, New York, NY 10011  (40.7388, -73.9957)
- `8`  41 Elizabeth Street, New York, NY 10013  (40.7204, -73.9956)
- `9`  117 West 17th Street, New York, NY 10011  (40.7407, -73.9967)
- `10` 131 Perry Street, New York, NY 10014  (40.7350, -74.0081)
- `11` 123 1st Avenue, New York, NY 10003  (40.7304, -73.9867)
- `13` 136 West 17th Street, New York, NY 10011  (40.7407, -73.9975)
- `14` Rubin Museum (142–148 West 17th Street), New York, NY 10011  (40.7408, -73.9978)
- `15` 133 East 15th Street, New York, NY 10003  (40.7340, -73.9862)
- `16` Stuyvesant Cove Park, New York, NY 10009  (40.7281, -73.9738)
- `17` 178 Spring Street, New York, NY 10012  (40.7248, -73.9971)
- `18` 36 Walker Street, New York, NY 10013  (40.7186, -74.0048)
- `19` 115 7th Avenue, New York, NY 10011  (40.7405, -73.9987)
- `20` CyntientOps HQ, Manhattan, NY  (40.7831, -73.9712)
- `21` 148 Chambers Street, New York, NY 10007  (40.7155, -74.0086)

DSNY notes:
- Unit counts and DSNY routing thresholds are tracked in `BuildingUnitValidator` and used for bin/route guidance.

**Counts & Health**

- Workers: 7 active (IDs 1,2,4,5,6,7,8)
- Buildings: 19 defined; 18 active (ID `2` removed)
- Clients: 6 active with mapped buildings

This inventory consolidates details previously spread across multiple documents and code comments. It should be kept in sync with `ClientBuildingSeeder`, `CanonicalIDs`, and building services.
