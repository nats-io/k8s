# NATS server bump script

The [workflow](nats-server-bump.yaml) uses `nats_server_bump.py` and `nats_server_bump_helpers.py` to select a stable server release and update `Chart.yaml`'s `appVersion` and `version`, plus `values.yaml`'s `container.image.tag`. YAML comments and formatting are preserved. The workflow handles Go dependency updates, chart tests, and PR creation.

For scheduling, GitHub App setup, secrets, and branch ownership, see [operating the automation](../nats-server-bump.md).

## Usage

Use **uv 0.13.5**, **Python 3.14.9**, and **gh 2.103.0**. Authenticate `gh` to github.com using `GH_TOKEN` or `gh auth login`. Run these commands from the repository root:

```sh
uv run --locked --python 3.14.9 .github/workflows/nats_server_bump.py check

uv run --locked --python 3.14.9 .github/workflows/nats_server_bump.py update \
  --current 2.15.1 --latest 2.15.2 --dry-run
```

Replace the example versions with the values from `check`. Remove `--dry-run` to apply the changes. Both commands accept `--chart-dir PATH`, defaulting to this repository's `helm/charts/nats`; use a temporary chart copy for local verification.

`check` requires GitHub and Docker Hub access and edits no chart files. `update` is offline and trusts the release selection from `check`, although `uv` may first download the pinned runtime and dependency.

## Behavior and outputs

- Select the highest published stable `vX.Y.Z` release across all pages, excluding drafts and prereleases.
- Return a successful no-op if the current app version is equal or newer, or Docker Hub returns 404 for the selected Alpine image. Do not fall back to an older release.
- Fail on API errors, invalid YAML, mismatched image tags, stale `--current` values, or a target that would reuse or lower the chart version.
- Validate both documents before writing. Duplicate keys and ambiguous target values are rejected. A filesystem failure during writing can still leave a partial update and stops PR creation.

`check` prints `bump=false` for a no-op, or `bump=true`, `current`, `latest`, and `image_tag` for an eligible update. It also appends these outputs to `$GITHUB_OUTPUT` when set. Exit codes are **0** for success/no-op, **1** for operational or validation failures, and **2** for invalid CLI syntax. Errors go to stderr; raw `gh` error output is suppressed to avoid exposing authentication details.

## Dependency and tool pinning

Exact versions and hashes reduce unexpected upstream changes; they do not prove a release is safe. Security fixes require reviewed updates.

| Component | Pin and enforcement |
| --- | --- |
| [PyYAML](https://github.com/yaml/pyyaml/releases/tag/6.0.3) | `==6.0.3` in script metadata; generated `.py.lock` records versions and artifact hashes |
| [uv](https://github.com/astral-sh/uv/releases/tag/0.13.5) | `0.13.5`, enforced by script metadata and installed with a committed SHA-256 |
| Python | `3.14.9` in the workflow and local commands |
| [GitHub CLI](https://github.com/cli/cli/releases/tag/v2.103.0) | `2.103.0`, downloaded and checksum-verified before extraction |
| [setup-uv](https://github.com/astral-sh/setup-uv/releases/tag/v10.3.2) and other Actions | Full commit SHA pins in the workflow |

Always execute with `uv run --locked`. The script's `no-build = true` requires wheels, avoiding separately resolved source-build dependencies. Download checksums are platform-specific; verify artifacts for your own OS and architecture. The hosted runner, existing Go toolchain selection, and runner-provided Helm are not fully pinned. Python downloads rely on metadata in the pinned uv release.

To update pins:

1. Review the upstream release and verify its checksum or Action commit. Update the version and checksum together; keep uv's workflow version and script `required-version` synchronized.
2. After changing the PyYAML requirement, regenerate the lockfile with the pinned uv:

   ```sh
   uv lock --script .github/workflows/nats_server_bump.py --python 3.14.9
   ```

3. Review versions, download hosts, and hashes in the diff. Never hand-edit the lockfile or bypass consistency checks with `--frozen`.
4. Verify the change, update this README, and commit the related files together. Normal workflow runs must not refresh pins.

## Verification

Preview and apply an update to a temporary chart copy. Confirm that only the three intended values change, including with quoted versions and inline comments, and that invalid inputs leave both files unchanged. Check release pagination, older maintenance releases, and Docker Hub 404/error handling when modifying discovery logic.

Run the existing chart tests with Go and Helm installed:

```sh
cd helm/charts/nats/test
go test
```

After merging, manually dispatch the workflow to verify the complete PR flow.
