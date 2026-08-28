# Gemini CLI Project Instructions: Harness Doom

This document outlines the architectural patterns, team conventions, and workflows established for this repository. These guidelines take absolute precedence over general defaults.

## 1. Kubernetes & Helm Deployment Conventions

### ✦ Dynamic NodePort Allocation (Collision Prevention)
To allow multiple environments (Dev, Prod, Staging) or multiple applications (Doom, Lemmings) to coexist on a single-node local cluster (such as Docker Desktop, Rancher Desktop, or k3s) without port collisions:
* **Never Hardcode NodePorts**: Always default `service.nodePort` to `null` in `values.yaml`:
  ```yaml
  service:
    type: NodePort
    port: 80
    targetPort: 8080
    nodePort: null
  ```
* **Guard Service Templates**: Always wrap the `nodePort` field in `service.yaml` with a conditional template guard so that the field is only included when explicitly overridden:
  ```yaml
  spec:
    type: {{ .Values.service.type }}
    ports:
      - port: {{ .Values.service.port }}
        targetPort: {{ .Values.service.targetPort }}
        {{- if .Values.service.nodePort }}
        nodePort: {{ .Values.service.nodePort }}
        {{- end }}
        protocol: TCP
        name: http
  ```

---

## 2. Harness CD Configuration Best Practices

### ✦ Infrastructure Definition Isolation
* **One App, One Infrastructure**: Never share a single Harness Infrastructure definition identifier (e.g., `demo_scarolan`) between two different applications/pipelines (e.g., Doom and Lemmings) unless they are intended to reside in the exact same namespace.
* **Dedicated Infrastructures**: Map each pipeline to dedicated, isolated infrastructures:
  * Dev Stage: `doom_dev_infra` pointing to `doom-dev` namespace.
  * Prod Stage: `doom_prod_infra` pointing to `doom-prod` namespace.

### ✦ Dynamic Environment Smoke Testing
* Always construct smoke-test endpoints dynamically using Harness-native stage/infra context variables. Avoid hardcoding service URLs or custom shell fallback logic:
  ```bash
  SVC_URL="http://<+infra.releaseName>.<+infra.namespace>.svc.cluster.local"
  ```
