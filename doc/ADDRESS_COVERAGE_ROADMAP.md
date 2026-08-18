# Address Coverage & Enhancement Roadmap

This document outlines the current data coverage of OpenStreetMap addresses, tag distributions from Taginfo, and technical strategies for increasing address density in future releases.

---

## 1. Global Taginfo Analysis

According to OpenStreetMap Taginfo statistics (August 2026), address tags exhibit the following worldwide distribution across over 1,600 `addr:*` key variations:

| Key | Total Count | Nodes | Ways / Multipolygons | Description / Role |
|:---|:---|:---|:---|:---|
| **`addr:housenumber`** | 182.7M | 91.8M | 90.6M | Explicit house number |
| **`addr:street`** | 171.8M | 81.9M | 89.7M | Assigned street name |
| **`addr:city`** | 132.7M | 61.7M | 70.8M | City or municipality name |
| **`addr:postcode`** | 116.9M | 52.7M | 64.0M | Postal code |
| **`addr:country`** | 52.7M | 27.0M | 25.7M | Country code / name |
| **`addr:place`** | 11.7M | 6.9M | 4.7M | Settlement / hamlet name used in place of street |
| **`addr:full`** | 10.8M | 10.4M | 0.35M | Full unparsed text address (common in data imports) |
| **`addr:interpolation`**| 2.57M | - | 2.57M | Address interpolation lines along streets |

---

## 2. Identified Coverage Gaps & Potential Enhancements

### A. Place Name Fallback (`addr:place`)
* **Context:** In many rural regions, villages, hamlets, and islands (e.g., in Germany, Spain, Japan, the UK), addresses do not have dedicated street names. Instead, houses are numbered directly relative to the place or hamlet name (e.g., `addr:housenumber=4`, `addr:place=Einöde`).
* **Impact:** Globally, **~11.7 million addresses** currently rely on `addr:place`.
* **Current Filter Behavior:** Filter conditions requiring `addr:street IS NOT NULL` omit these addresses.
* **Proposed Enhancement:** Allow `COALESCE(addr_street, addr_place)` as the `street` column, or add a dedicated `place` column.

### B. Address Interpolation (`addr:interpolation`)
* **Context:** In areas where individual building footprints and house numbers have not yet been mapped, OSM mappers connect start and end address nodes using an interpolation line (`way`).
* **Distribution:**
  - `addr:interpolation=odd`: ~1.27M ways (49.4%)
  - `addr:interpolation=even`: ~1.27M ways (49.4%)
  - `addr:interpolation=all`: ~26.5k ways (1.0%)
  - `addr:interpolation=alphabetic`: ~1.1k ways (<0.1%)
* **Estimated Yield:** With an average of 4 to 8 interpolated house numbers per segment, resolving interpolation lines represents an estimated **10 to 20 million additional synthetic address points globally** (a 5–10% increase in total address points).
* **Implementation Concept:**
  - Pre-filter `w/addr:interpolation` ways and their boundary nodes.
  - Parse the interpolation rule (`even`, `odd`, `all`, `alphabetic`, or numeric step).
  - Compute interpolated point coordinates equidistant along the geometry linestring.
  - Export synthesized address points matching the standard schema.

### C. Relation Resolution (`associatedStreet`)
* **Context:** Older OSM mapping conventions grouped house numbers and streets using `associatedStreet` relations rather than tagging `addr:street` directly on each node/building.
* **Implementation Concept:** Expand relation processing in Osmium or DuckDB spatial ingestion to inherit street names from parent `associatedStreet` relations when `addr:street` is omitted on member elements.

### D. Unstructured Address Parsing (`addr:full`)
* **Context:** Around 10.8 million features carry only a full text address in `addr:full`.
* **Implementation Concept:** Evaluate lightweight regex-based or libpostal-based parsers to split `addr:full` into `street`, `number`, `postcode`, and `city` when structured `addr:*` tags are missing.

---

## 3. Reference Summary

| Enhancement Area | Target Tags | Estimated Global Address Yield | Complexity |
|:---|:---|:---|:---|
| Place Name Fallback | `addr:place` | ~11.7 Million | Low (SQL / schema update) |
| Address Interpolation | `addr:interpolation` | ~10.0 – 20.0 Million | Medium (geometry interpolation step) |
| Relation Resolution | `type=associatedStreet` | ~1.0 – 3.0 Million | Medium (relational tag inheritance) |
| Unstructured Parsing | `addr:full` | ~5.0 – 10.0 Million | High (NLP / address parsing dependencies) |
