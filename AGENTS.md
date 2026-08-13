# AGENTS.md — Development Guidelines for `osm-addresses`

To ensure consistent pipeline execution, geographical coverage, and clean Git workflows in `osm-addresses`, developers and AI agents must adhere to the following rules:

---

## Architecture & Project Relationships

- **Upstream Dependency (`osm-tools`):**
  `osm-addresses` relies on the PBF download pipeline (`azure-pipelines-download-osm.yml` in `osm-tools`, pipeline definition ID 3).
- **Execution Container (`osm2parquet`):**
  DuckDB-based converter (`krizleebear/osm2parquet`) pre-packaging DuckDB CLI + `spatial` extension.
- **Data Flow:**
  1. `osm-download` pipeline downloads and caches Geofabrik `.osm.pbf` extracts.
  2. `addresses-parquet` pipeline downloads cached PBF artifacts and runs `/app/entrypoint.sh` inside `osm2parquet`.
  3. DuckDB extracts `addr:housenumber` and `addr:street` features into ZSTD-compressed GeoParquet files.

---

## Git Workflow & Rules

1. **Azure DevOps Job Container Entrypoint Safety:**
   - Docker images intended for Azure DevOps job containers (`container: <image>`) must NOT define an exec-form `ENTRYPOINT` that exits on unknown arguments (such as `ENTRYPOINT ["/app/entrypoint.sh"]`), because Azure DevOps starts job containers with `sleep infinity`. Use `CMD ["/bin/bash"]` in the Dockerfile and invoke processing scripts explicitly in pipeline steps.
2. **Immutable Container Image Digest Pinning:**
   - In pipeline container resource definitions using `mirror.gcr.io`, reference images with immutable digests (`image: mirror.gcr.io/owner/repo@sha256:...`) rather than mutable tags (`:latest` or version tags) to prevent stale cache hits on runners.
3. **DuckDB Script Template Substitution Invariant:**
   - DuckDB `COPY ... TO` statements require string literal paths. Do not attempt `getvariable()` inside `COPY TO`. Use `sed` token substitution (`__INPUT_PBF__`, `__OUTPUT_PARQUET__`) on SQL templates before piping into `duckdb`.
4. **Conventional Commits:**
   - Use conventional commit prefixes (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`).
5. **English Output Standard:**
   - Log outputs, diagnostic error messages, and pipeline notices must be written strictly in clear English.
