Replaced the workflow's version-selection and YAML-editing shell pipelines with a Python CLI using `argparse`, PyYAML, and `gh` for authenticated, paginated GitHub API access.

- `check` selects the highest published stable release and waits for its Alpine image on Docker Hub. `update` validates the current chart values and changes only the three intended YAML fields, preserving comments, formatting, and quotes. `--dry-run` previews the diff.
- The workflow retains Go dependency updates, chart tests, and PR creation. Python helpers are separate from the CLI entry point, with type annotations and docstrings.
- Python dependencies use exact versions and a committed uv script lockfile. Execution uses `--locked`; source builds are disabled. The workflow pins uv, Python, and gh, verifies uv and gh archive checksums, and pins the new setup Action by commit SHA.
- Added `.github/workflows/README-nats_server_bump.md` with usage, failure behavior, verification, and a dedicated dependency-pinning section. The existing operations guide links to it.

Validation passed: 28 temporary scenarios, the existing chart Go tests (`go test ./...`), lockfile enforcement, and archive checksum verification. A live discovery check correctly returned `bump=false` while the selected release's Alpine image was unavailable. The full GitHub Actions and PR-creation flow still needs a workflow run.
