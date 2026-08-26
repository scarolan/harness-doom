# DOOM - Deployed by Harness

<p align="center">
  <img src="screenshots/doom0.png" width="400" alt="DOOM Title Screen">
  <img src="screenshots/doom1.png" width="400" alt="DOOM Gameplay">
</p>

> "Will it run DOOM?" — Every engineer, at every company, since 1993.

Yes. Yes it will. This repo deploys a fully playable DOOM (1993 shareware) to a Kubernetes cluster using a [Harness](https://harness.io) CI/CD pipeline.

The container packages the original DOOM shareware compiled to WebAssembly (via [Chocolate Doom](https://www.chocolate-doom.org/) + Emscripten) served by nginx. WASD + mouse controls, E1M1 music, native speed. The Harness pipeline builds the container, pushes it to a registry, deploys to dev, runs a smoke test, gates on manual approval, and promotes to prod.

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
├── index.html          # Browser UI - WASM DOOM with WASD + music
├── nginx.conf          # Web server config with /healthz endpoint
├── Dockerfile          # Serves pre-built WASM + assets via nginx
├── Dockerfile.wasm-gate # Full from-source WASM build (CI)
├── wasm-artifacts/     # Pre-built doom.js + doom.wasm
├── default.cfg         # WASD key bindings + mouse config
├── e1m1.mp3            # E1M1 soundtrack
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

The Dockerfile packages pre-built WebAssembly artifacts (Chocolate Doom compiled with Emscripten) into an nginx container. At runtime, the browser loads the WASM binary directly — no emulation layer, no DOSBox, no CDN dependencies. Native DOOM engine running at full speed in your browser, deployed by a CI/CD pipeline.

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

All for a 32-year-old game compiled to WebAssembly served by nginx deployed by Helm orchestrated by Harness triggered by a git push.

## "But does it actually *run* DOOM?"

Yes. For the pedants in the back: Harness doesn't just *deploy* DOOM — it *runs* DOOM.

`app/Dockerfile.runner` builds a headless container with [Chocolate Doom](https://www.chocolate-doom.org/) (a faithful source port). When executed as a Kubernetes Job on the same infrastructure managed by the Harness delegate, it processes DOOM's built-in demo recording frame-by-frame:

```
timed 5026 gametics in 127 realtics (1385.118164 fps)
```

5,026 game frames rendered at 1,385 FPS on the delegate's cluster. The DOOM engine initialized, loaded the WAD, ran the renderer, ticked the game logic, and completed — all orchestrated by Harness. No browser, no WebAssembly, no tricks. Native DOOM binary, running on Harness compute.

So to be precise: Harness *deploys* playable DOOM (the browser version) **and** *runs* DOOM (the headless timedemo). Both definitions are satisfied. You're welcome.

## License

This repo's code is MIT licensed. DOOM shareware is freely distributable per id Software's original terms. The shareware WAD and executable are downloaded at build time and not stored in this repository.

---

*Rip and tear, until it is done.* 🔥
