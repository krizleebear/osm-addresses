# osm-addresses

Global address dataset extracted from OpenStreetMap, published as **GeoParquet** (ZSTD-compressed).

## Data

Each file contains all address-tagged features (`addr:housenumber` + `addr:street`) for one region:

- **Points**: OSM nodes with address tags (direct coordinates)
- **Buildings & Polygons**: OSM ways and multipolygons with address tags (centroid used as point geometry)

### Schema

| Column | Type | Description |
|:---|:---|:---|
| `street` | `varchar` | `addr:street` |
| `number` | `varchar` | `addr:housenumber` |
| `postcode` | `varchar` | `addr:postcode` |
| `city` | `varchar` | `addr:city` |
| `geometry` | `geometry('epsg:4326')` | Point geometry (WGS84 EPSG:4326) |

### Example Query (DuckDB)

```sql
LOAD spatial;
SELECT street, number, postcode, city, ST_AsText(geometry)
FROM read_parquet('DE_germany.addresses.parquet')
WHERE city = 'München'
LIMIT 10;
```

### Example (GeoPandas)

```python
import geopandas as gpd
gdf = gpd.read_parquet("DE_germany.addresses.parquet")
```

## Pipelines

Data is produced and published by two Azure DevOps pipelines:

1. **`azure-pipelines.yml`** (`addresses-parquet-pipeline`):  
   - Downloads cached OSM PBF extracts from the `osm-download` pipeline (definition ID 3).
   - Pre-filters address features via `osmium tags-filter` to conserve disk space.
   - Converts filtered PBFs to ZSTD-compressed GeoParquet via [DuckDB](https://duckdb.org/) spatial extension (`osm2parquet` container).
   - Packages continental tarballs (`addresses-parquet-europe.tar.gz`, `asia`, `africa`, etc.) and global archive (`addresses-parquet-all.tar.gz`).
2. **`azure-pipelines-release.yml`** (`addresses-release-pipeline`):  
   - Manual GitHub Release pipeline (`trigger: none`).
   - Downloads latest build artifacts, prepares release notes, and publishes GitHub Release assets (`.tar.gz` archives and individual `.parquet` files).

## Coverage

**Global Coverage**: 169 region definitions spanning Africa, Asia, Europe, Oceania, Central America, North America, and South America matching the [osm-polygons](https://github.com/krizleebear/osm-polygons) dataset.

## License

Data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), [ODbL](https://opendatacommons.org/licenses/odbl/).
