# osm-addresses

Global address dataset extracted from OpenStreetMap, published as **GeoParquet** (ZSTD-compressed).

## Data

Each file contains all address-tagged features (`addr:housenumber` + `addr:street`) for one region:

- **Points**: OSM nodes with address tags (direct coordinates)
- **Buildings**: OSM multipolygons with address tags (centroid used as geometry)

### Schema

| Column | Type | Description |
|:---|:---|:---|
| `street` | `varchar` | `addr:street` |
| `number` | `varchar` | `addr:housenumber` |
| `postcode` | `varchar` | `addr:postcode` |
| `city` | `varchar` | `addr:city` |
| `geometry` | `geometry('epsg:4326')` | Point geometry (WGS84) |

### Example Query (DuckDB)

```sql
LOAD spatial;
SELECT street, number, postcode, city
FROM read_parquet('DE_germany.addresses.parquet')
WHERE city = 'München'
LIMIT 10;
```

### Example (GeoPandas)

```python
import geopandas as gpd
gdf = gpd.read_parquet("DE_germany.addresses.parquet")
```

## Pipeline

Data is produced by an Azure DevOps pipeline:

1. **osm-download** (`osm-tools` repo): Downloads and caches OSM PBF files from [Geofabrik](https://download.geofabrik.de/)
2. **addresses-parquet** (this repo): Converts cached PBF files → GeoParquet via [DuckDB](https://duckdb.org/) spatial extension (no Java required)

## Coverage

Currently: **DACH + Benelux** pilot (Germany, Austria, Switzerland, Netherlands, Belgium, Luxembourg).

Planned: Global coverage (169 regions) matching the [osm-polygons](https://github.com/krizleebear/osm-polygons) dataset.

## License

Data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), [ODbL](https://opendatacommons.org/licenses/odbl/).
