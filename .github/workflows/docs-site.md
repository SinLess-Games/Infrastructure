---
on:
  push:
    branches:
      - main
    paths:
      - "Docs/**"
      - "mkdocs.yml"
      - ".github/workflows/docs-site.md"
      - "Kubernetes/apps/prod/sinless-games/docs/**"
  workflow_dispatch:
  skip-bots: github-actions

description: "Build, publish, and GitOps-update the MkDocs documentation site image"
engine: copilot
strict: true
run-name: "Docs Site Publisher"
runs-on: ubuntu-latest
runs-on-slim: ubuntu-latest
timeout-minutes: 30

if: ${{ github.event_name != 'push' || !contains(github.event.head_commit.message || '', '[skip docs deploy]') }}

concurrency:
  group: docs-site-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  actions: read
  checks: read
  pull-requests: read

runtimes:
  python:
    version: "3.12"

env:
  IMAGE_NAME: ghcr.io/${{ github.repository_owner }}/infrastructure-docs
  DEPLOYMENT_MANIFEST: Kubernetes/apps/prod/sinless-games/docs/deployment-docs.yaml
  DOCS_REQUIREMENTS: Docs/requirements.txt
  DOCS_DOCKERFILE: Docs/Dockerfile

network:
  allowed:
    - defaults
    - python
    - containers

tools:
  edit:
  bash:
    - awk
    - cat
    - cut
    - docker:*
    - find
    - git:*
    - grep
    - head
    - jq
    - ls
    - mkdir
    - mkdocs
    - pip
    - pip3
    - pwd
    - python
    - python3
    - sed
    - sha256sum
    - tail
    - tee
    - test
    - tr
    - xargs

jobs:
  build_docs_image:
    name: Build and publish docs image
    runs-on: ubuntu-latest
    timeout-minutes: 25
    permissions:
      contents: read
      packages: write
    env:
      IMAGE_NAME: ghcr.io/${{ github.repository_owner }}/infrastructure-docs
    outputs:
      image-ref: ${{ steps.image.outputs.image_ref }}
      image-tag: ${{ steps.image.outputs.image_tag }}
      short-tag: ${{ steps.image.outputs.short_tag }}
    steps:
      - name: Build MkDocs site
        run: |
          set -euo pipefail

          test -f Docs/requirements.txt
          test -f mkdocs.yml
          test -f Docs/Dockerfile

          python3 -m pip install --upgrade pip
          python3 -m pip install -r Docs/requirements.txt
          python3 -m mkdocs build --clean --strict

      - name: Build and push docs image
        id: image
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          set -euo pipefail

          IMAGE_TAG="sha-${GITHUB_SHA}"
          SHORT_TAG="sha-${GITHUB_SHA::7}"
          IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"

          echo "${GITHUB_TOKEN}" | docker login ghcr.io \
            --username "${GITHUB_ACTOR}" \
            --password-stdin

          docker buildx version

          docker buildx create --name docs-site-builder --use 2>/dev/null || docker buildx use docs-site-builder

          docker buildx build \
            --file Docs/Dockerfile \
            --tag "${IMAGE_NAME}:main" \
            --tag "${IMAGE_REF}" \
            --tag "${IMAGE_NAME}:${SHORT_TAG}" \
            --label "org.opencontainers.image.source=https://github.com/${GITHUB_REPOSITORY}" \
            --label "org.opencontainers.image.revision=${GITHUB_SHA}" \
            --push \
            .

          {
            echo "image_ref=${IMAGE_REF}"
            echo "image_tag=${IMAGE_TAG}"
            echo "short_tag=${SHORT_TAG}"
          } >> "${GITHUB_OUTPUT}"

safe-outputs:
  create-pull-request:
    max: 1
    title-prefix: "[docs] "
    draft: false
    fallback-as-issue: true
    allowed-files:
      - Kubernetes/apps/prod/sinless-games/docs/deployment-docs.yaml

---

# Docs Site Publisher

Build, publish, and prepare the GitOps manifest update for the production documentation site.

The deterministic `build_docs_image` job has already built the MkDocs site and pushed the container image to GHCR before this agent starts.

## Inputs from deterministic build

Use this image reference:

`${{ needs.build_docs_image.outputs.image-ref }}`

Expected format:

`ghcr.io/<owner>/infrastructure-docs:sha-<full-git-sha>`

## Goals

- verify the docs deployment manifest exists
- update the docs deployment image to the exact image reference produced by the build job
- keep the manifest change tightly scoped
- create one pull request for the GitOps image update
- do nothing if the manifest already points at the published image

## Required repository paths

- docs source: `Docs/**`
- MkDocs config: `mkdocs.yml`
- docs Dockerfile: `Docs/Dockerfile`
- deployment manifest: `Kubernetes/apps/prod/sinless-games/docs/deployment-docs.yaml`

## Execution rules

Do not rebuild the image in the agent step.

Do not run Docker in the agent step.

Do not modify docs content, Dockerfiles, Helm values, namespaces, services, or unrelated Kubernetes manifests.

Only edit:

`Kubernetes/apps/prod/sinless-games/docs/deployment-docs.yaml`

Use the full SHA image tag from the deterministic build output. Do not shorten it when updating the manifest.

## Manifest update procedure

From the repository root, run:

```bash
set -euo pipefail

IMAGE_REF='${{ needs.build_docs_image.outputs.image-ref }}'
MANIFEST='Kubernetes/apps/prod/sinless-games/docs/deployment-docs.yaml'

test -n "${IMAGE_REF}"
test -f "${MANIFEST}"

python3 - <<'PY'
from pathlib import Path
import os
import sys

image_ref = os.environ["IMAGE_REF"]
path = Path(os.environ["MANIFEST"])

text = path.read_text()
lines = text.splitlines(keepends=True)

changed = 0
new_lines = []

for line in lines:
    stripped = line.lstrip()
    if stripped.startswith("image: "):
        indent = line[: len(line) - len(stripped)]
        newline = "\n" if line.endswith("\n") else ""
        new_lines.append(f"{indent}image: {image_ref}{newline}")
        changed += 1
    else:
        new_lines.append(line)

if changed != 1:
    print(f"Expected exactly one image field in {path}, found {changed}", file=sys.stderr)
    sys.exit(1)

new_text = "".join(new_lines)

if new_text != text:
    path.write_text(new_text)
PY

git diff -- "${MANIFEST}"
git diff --check -- "${MANIFEST}"

grep -F "image: ${IMAGE_REF}" "${MANIFEST}"
```

## Pull request rules

Create a pull request only when the manifest changed.

Use this PR title:

`docs: publish site image`

Use this PR body:

```markdown
## Docs site publish

Published the MkDocs site image and updated the production GitOps manifest.

## Image

`${{ needs.build_docs_image.outputs.image-ref }}`

## Validation

- MkDocs build completed with `mkdocs build --clean --strict`
- Container image was pushed to GHCR
- Deployment manifest now references the published immutable SHA tag

## Notes

This replaces the old direct commit behavior with a safe GitOps PR flow.
```

## No-op behavior

If the manifest already references `${{ needs.build_docs_image.outputs.image-ref }}`, do not create a pull request.

## Failure behavior

Fail the run if:

- the image reference output is empty
- the deployment manifest is missing
- the deployment manifest does not contain exactly one `image:` field
- `git diff --check` fails
- the final manifest does not contain the expected image reference

## Formatting rules

- keep changes minimal
- keep markdown concise
- do not make broad deployment claims
- do not claim Argo CD has synced the change
- do not modify unrelated files