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

## Pipeline Architecture & Conventions

1. **Build Pipeline (`azure-pipelines.yml` / `addresses-parquet-pipeline`):**
   - 169 region matrix definitions following Geofabrik hierarchy across 7 continents.
   - Includes single-threaded `warmup` stage to prime `mirror.gcr.io` CDN cache before matrix jobs run.
   - Publishes continental archives (`addresses-parquet-europe.tar.gz`, etc.), global archive (`addresses-parquet-all.tar.gz`), and pre-filtered address PBF artifacts (`addresses-pbf-$(CC)-$(REGION)`).

2. **Standalone Manual GitHub Release Pipeline (`azure-pipelines-release.yml` / `addresses-release-pipeline`):**
   - Releases are triggered manually on-demand (`trigger: none`).
   - Downloads latest build artifacts, packages global (`addresses-parquet-all.tar.gz`), continental (`addresses-parquet-*.tar.gz`), and individual country (`.parquet`) files, and publishes them as GitHub Release assets using service connection `3c34db30-d57b-42e2-a970-857bd932c6c0`.

---

## Git Workflow & Rules

1. **Azure DevOps Job Container Entrypoint Safety:**
   - Docker images intended for Azure DevOps job containers (`container: <image>`) must NOT define an exec-form `ENTRYPOINT` that exits on unknown arguments (such as `ENTRYPOINT ["/app/entrypoint.sh"]`), because Azure DevOps starts job containers with `sleep infinity`. Use `CMD ["/bin/bash"]` in the Dockerfile and invoke processing scripts explicitly in pipeline steps.
2. **Docker Schema 2 Manifest Requirement for `mirror.gcr.io`**:
   - Container images pushed to Docker Hub for `mirror.gcr.io` consumption must be built in Docker Schema 2 format (`application/vnd.docker.distribution.manifest.v2+json`) using standard `docker build` or `docker buildx build --provenance=false`. Modern OCI attestation/provenance blobs cause `unknown blob` 404 errors on `mirror.gcr.io`.
3. **DuckDB Script Template Substitution Invariant:**
   - DuckDB `COPY ... TO` statements require string literal paths. Do not attempt `getvariable()` inside `COPY TO`. Use `sed` token substitution (`__INPUT_PBF__`, `__OUTPUT_PARQUET__`) on SQL templates before piping into `duckdb`.
4. **Azure DevOps Parameter Condition Syntax**:
   - In Azure DevOps task/job `condition:` expressions, template parameters MUST be wrapped in `${{ eq(parameters.name, value) }}`. Raw `parameters.name` references outside `${{ }}` trigger `Unrecognized value: 'parameters'` errors.
   - In Bash scripts, handle both `"false"` and `"False"` because template expansion converts boolean false to `"False"`.
5. **Osmium Tag Pre-filtering for Runner Disk Conservation**:
   - When processing large country extracts (e.g. Germany 4.4 GB), pre-filter features using `osmium tags-filter` first, delete the raw input PBF immediately (`rm -rf osm-data-$(REGION)`), and run downstream spatial tools (DuckDB, GDAL) on the small filtered PBF to keep peak disk usage under 5 GB.
6. **Conventional Commits:**
   - Use conventional commit prefixes (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`).
7. **English Output Standard:**
   - Log outputs, diagnostic error messages, and pipeline notices must be written strictly in clear English.
