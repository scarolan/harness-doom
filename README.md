# DOOM - Deployed by Harness

![DOOM Title Screen](screenshots/doom-title.png)
![DOOM Gameplay](screenshots/doom-gameplay.png)

> "Will it run DOOM?" — Every engineer, at every company, since 1993.

Yes. Yes it will. This repo deploys a fully playable DOOM (1993 shareware) to a Kubernetes cluster using a [Harness](https://harness.io) CI/CD pipeline.

The container packages the original DOOM shareware in a browser-playable format (via [js-dos](https://js-dos.com)) served by nginx. The Harness pipeline builds the container, pushes it to a registry, deploys to dev, runs a smoke test, gates on manual approval, and promotes to prod.

```
commit → build container → push to registry → deploy to dev → smoke test → approval gate → deploy to prod
                                                                                    ↑
                                                                          (you approve DOOM for prod)
```

## Prerequisites

- A Kubernetes cluster (any: k3s, EKS, GKE, AKS, kind, minikube...)
- A [Harness](https://app.harness.io) account (free tier works)
- A Harness Delegate running in your cluster
- `kubectl`, `helm`, and `docker` (or equivalent) installed locally
- A container registry (Harness Artifact Registry, Docker Hub, ECR, etc.)

## Quick Start (Local)

If you just want to see DOOM running locally without a pipeline:

```bash
# Build and deploy to your local cluster
./scripts/setup.sh

# Open in browser
open http://localhost:30666

# Tear it down when you're done
./scripts/teardown.sh
```

## Deploy via Harness Pipeline

### 1. Set up your Harness project

Create a project in Harness (or use an existing one). You'll need:
- A **Kubernetes connector** pointing to your cluster
- A **Docker Registry connector** pointing to your container registry
- A **code repo connector** pointing to this repo (GitHub, Harness Code, etc.)

### 2. Create the service

In your Harness project, create a Service with:
- **Deployment type:** Native Helm
- **Manifest source:** this repo, path `helm/harness-doom`
- **Artifact source:** your container registry, image path for `harness-doom`

### 3. Create environments and infrastructure

- **dev** environment → infrastructure definition pointing to your cluster + a `doom` namespace
- **prod** environment → infrastructure definition (same cluster, or a different one for realism)

### 4. Import the pipeline

Import `.harness/pipeline.yaml` into your project. Fill in the `<+input>` runtime inputs:
- Code repo connector
- Kubernetes infrastructure connector
- Docker registry connector
- Image repo path (e.g., `your-registry.io/harness-doom`)
- Infrastructure definition identifiers

### 5. Run it

Execute the pipeline. Watch it:
1. Clone this repo
2. Build the DOOM container (first build ~5 min due to downloading shareware assets)
3. Push to your registry
4. Deploy to dev namespace
5. Smoke test (curls the health endpoint + verifies "DOOM" in page)
6. Wait for your approval (the governance demo moment)
7. Deploy to prod

Then open `http://<node-ip>:30666` and play DOOM.

## How It Works

```
app/
├── index.html      # Browser UI - loads js-dos, renders DOOM
├── nginx.conf      # Web server config with /healthz endpoint
├── Dockerfile      # Multi-stage: downloads shareware → bundles → serves
└── .dockerignore

helm/harness-doom/  # Helm chart for k8s deployment
├── Chart.yaml
├── values.yaml
└── templates/

.harness/
└── pipeline.yaml   # Harness pipeline definition (parameterized)

scripts/
├── setup.sh        # Local deploy (no pipeline needed)
├── teardown.sh     # Clean removal
└── smoke-test.sh   # Validates the deployment works
```

The Dockerfile does the heavy lifting:
1. Downloads DOOM shareware v1.9 (freely distributable, ~4MB WAD + EXE)
2. Creates a `.jsdos` bundle (DOSBox-in-WebAssembly game package)
3. Packages everything in an nginx container

At runtime, the browser loads js-dos from CDN, which emulates DOSBox in WebAssembly, and runs the original DOOM.EXE with the shareware WAD. Full game, in a browser, deployed by a CI/CD pipeline.

## Customization

| Variable | Default | Description |
|----------|---------|-------------|
| `DOOM_NAMESPACE` | `doom` | Kubernetes namespace |
| `DOOM_RELEASE` | `harness-doom` | Helm release name |
| `DOOM_IMAGE` | `harness-doom` | Container image name |
| `DOOM_TAG` | `latest` | Image tag |

Override in your pipeline or local env:
```bash
DOOM_NAMESPACE=doom-prod DOOM_TAG=build-42 ./scripts/setup.sh
```

## Why?

Because every platform must answer the question. And because deploying a game from 1993 through a modern CI/CD pipeline with governance gates, smoke tests, and progressive delivery is genuinely funny — and also demonstrates every capability that matters:

- Container builds (multi-stage, external asset download)
- Artifact management (push/pull from registry)
- Helm-based deployment
- Health checks and smoke tests
- Approval gates (human-in-the-loop governance)
- Progressive delivery (dev → approval → prod)
- GitOps trigger (push to main → pipeline fires)

All for a 32-year-old game that runs in DOSBox emulated in WebAssembly served by nginx deployed by Helm orchestrated by Harness triggered by a git push.

## License

This repo's code is MIT licensed. DOOM shareware is freely distributable per id Software's original terms. The shareware WAD and executable are downloaded at build time and not stored in this repository.

---

*Rip and tear, until it is done.* 🔥
