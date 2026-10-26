# Automated nats-server chart bumps

The `nats-server-bump` workflow (`.github/workflows/nats-server-bump.yaml`) runs daily and opens a pull request bumping the `nats` Helm chart to the newest stable nats-server release. This document describes what the workflow does, what it needs in order to run, and how to set that up.

## What the workflow does

1. Reads `appVersion` from `helm/charts/nats/Chart.yaml`.
2. Finds the highest published stable release in `nats-io/nats-server`. Drafts and pre-releases (`-RC.n`, `-beta.n`) are skipped. Using releases rather than tags means a tag pushed ahead of its release is not selected. Taking the highest release means maintenance releases on an older line (for example 2.14.x while 2.15.x is current) are ignored.
3. Stops if the chart is already at that version. Fails if the chart `version` is already at or above the new release, since the chart repository skips already-published versions and a reused version would leave the bump unpublished. That only happens after a chart-only version bump and needs manual handling.
4. Stops if the `nats:X.Y.Z-alpine` tag does not exist on Docker Hub yet. The official image is published only after the corresponding `docker-library/official-images` pull request has been merged and built, so this check is the gate that waits for that process.
5. Updates the same files as a manual bump (see nats-io/k8s PR 1198):
   - `helm/charts/nats/Chart.yaml`: `appVersion` and `version` are both set to the new release.
   - `helm/charts/nats/values.yaml`: the nats-server image tag.
   - `helm/charts/nats/test/go.mod` and `go.sum`: via `go get` and `go mod tidy`.
6. Runs the chart's Go tests.
7. Opens a pull request titled `Bump nats to vX.Y.Z` from the branch `bump/nats-server`. The branch name is fixed, so re-runs update the existing PR instead of opening duplicates. The repository's automatic head-branch deletion removes the branch after merge.

The workflow can also be started manually from the Actions tab (`workflow_dispatch`).

Dependabot is configured to ignore the `nats` image in `helm/charts/nats` so it does not open a competing PR. The other images in that chart (nats-box, config reloader, Prometheus exporter) are still handled by Dependabot.

## Why a GitHub App is required

Pull requests created with the default `GITHUB_TOKEN` do not trigger other workflows, so the chart tests and lint checks would never run on the bump PR. Creating the PR with a GitHub App installation token avoids this. A fine-grained personal access token would also work but ties the automation to one person's account.

## One-time setup

Repository admin access to `nats-io/k8s` and owner access to the `nats-io` organization are required.

### 1. Create the GitHub App

Go to the organization settings, Developer settings, GitHub Apps, New GitHub App.

- Name: something descriptive, for example `nats-k8s-bump`.
- Homepage URL: `https://github.com/nats-io/k8s`.
- Webhook: uncheck Active. No webhook is needed.
- Repository permissions:
  - Contents: Read and write (push the bump branch).
  - Pull requests: Read and write (open and update the PR).
  - Metadata: Read-only (added automatically).
- Where can this GitHub App be installed: Only on this account.

Create the app. On the app's General page note the App ID, then under Private keys choose Generate a private key and keep the downloaded `.pem` file.

### 2. Install the app

On the app's Install App page, install it on the `nats-io` organization and restrict it to the `k8s` repository only.

### 3. Add the repository secrets

In `nats-io/k8s`, go to Settings, Secrets and variables, Actions, and add two repository secrets:

| Secret name | Value |
| --- | --- |
| `NATS_BUMP_APP_ID` | The App ID from step 1 |
| `NATS_BUMP_APP_PRIVATE_KEY` | The full contents of the `.pem` file, including the BEGIN and END lines |

### 4. Verify

Run the `nats-server-bump` workflow manually from the Actions tab. Each run logs the current chart version, the latest release, and whether the image is published. When a bump is pending and the image exists, a PR appears from the app's bot account and the usual CI checks run on it.

## Operational notes

- The daily schedule is 07:00 UTC. A release that lands on Docker Hub after that time is picked up the next day, or immediately with a manual run.
- The `bump/nats-server` branch is owned by the automation. Every run regenerates it from `main` and force-pushes if the result differs, so manual commits on it are lost on the next run. If the PR needs extra changes, make them in a separate PR and merge that first, or disable the workflow in the Actions tab while editing the branch and re-enable it after merging.
- If a release must be skipped, closing the PR is not enough. The workflow opens a new PR on the next run while that release remains the highest stable release. Bump the chart past it manually, or disable the workflow until the next release.
- Rotating the private key: generate a new key on the app's General page, update `NATS_BUMP_APP_PRIVATE_KEY`, then delete the old key.
