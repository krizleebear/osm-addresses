-- DuckDB SQL: OSM PBF -> GeoParquet (address export)
-- Placeholder tokens __INPUT_PBF__ and __OUTPUT_PARQUET__ are substituted by
-- entrypoint.sh using sed before the script is piped to duckdb stdin.
-- This avoids the restriction that COPY TO requires a string literal path.

LOAD spatial;

COPY (
    -- Node/point features with address tags
    SELECT
        addr_street     AS street,
        addr_housenumber AS number,
        addr_postcode   AS postcode,
        addr_city       AS city,
        geom            AS geometry
    FROM ST_Read(
        '__INPUT_PBF__',
        layer        = 'points',
        open_options = ['CONFIG_FILE=/app/osmconf.ini']
    )
    WHERE addr_housenumber IS NOT NULL
      AND addr_street      IS NOT NULL

    UNION ALL

    -- Building polygon features: use centroid as point geometry
    SELECT
        addr_street          AS street,
        addr_housenumber     AS number,
        addr_postcode        AS postcode,
        addr_city            AS city,
        ST_Centroid(geom)       AS geometry
    FROM ST_Read(
        '__INPUT_PBF__',
        layer        = 'multipolygons',
        open_options = ['CONFIG_FILE=/app/osmconf.ini']
    )
    WHERE addr_housenumber IS NOT NULL
      AND addr_street      IS NOT NULL

) TO '__OUTPUT_PARQUET__' (FORMAT PARQUET, COMPRESSION 'ZSTD');
