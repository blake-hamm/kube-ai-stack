# AGENTS.md

Guidelines for AI coding agents working in the **kube-ai-stack** repository — a Helm chart for deploying LLM backends on Kubernetes with LiteLLM gateway, KubeElasti auto-scaling, and optional MLflow/Phoenix observability.

## Key Commands

```bash
helm lint charts/kube-ai-stack [-f my-values.yaml]
helm template my-release charts/kube-ai-stack [-f my-values.yaml] [--debug]
helm install my-release charts/kube-ai-stack --dry-run
helm dependency update charts/kube-ai-stack
helm test my-release

# Render specific template
helm template my-release charts/kube-ai-stack --show-only templates/<file>.yaml
```

## File Structure

```
charts/kube-ai-stack/
├── Chart.yaml
├── values.yaml
├── values.schema.json        # JSON Schema draft-07 validation
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── pvc.yaml
│   ├── litellm-configmap.yaml
│   ├── elastiservice.yaml
│   └── servicemonitor.yaml
├── tests/
│   └── test-connection.yaml
└── mlflow/                   # local subchart
```

## Code Style

- **YAML**: 2-space indent; quote strings with special chars or ambiguous types; `|` for multi-line strings
- **Whitespace**: use `{{-`/`-}}` to trim; use `| nindent N` for nested blocks
- **Names**: lowercase-hyphenated; PVCs get `-cache` suffix, ConfigMaps get `-template` suffix

## Helm Conventions

**Value merging** (always use this pattern when iterating models):
```yaml
{{- $merged := mergeOverwrite (deepCopy $.Values.global) . -}}
```

**Label helpers** (pass dict for model-scoped helpers):
```yaml
{{- include "kube-ai-stack.labels" . | nindent 4 }}
{{- include "kube-ai-stack.modelLabels" (dict "model" . "root" $) | nindent 4 }}
```
Available: `labels`, `modelLabels`, `serviceLabels`, `pvcLabels`, `configMapLabels`, `modelSelectorLabels`

**ArgoCD sync-wave** (all resources require this annotation):
```yaml
argocd.argoproj.io/sync-wave: {{ $.Values.integrations.argocd.syncWave.<type> | quote }}
```
Default order — ConfigMaps/PVCs: `"20"`, Deployments: `"20"`, Services: `"21"`, ServiceMonitors: `"22"`, ElastiServices: `"23"`

**Helper definition pattern** (`_helpers.tpl`):
```yaml
{{/*
Description
*/}}
{{- define "kube-ai-stack.helperName" -}}
{{- /* logic */ -}}
{{- end }}
```

**Error handling**:
```yaml
{{ .Values.foo | required "foo is required" }}
{{ .service.port | default $.Values.global.service.port }}
```

## Values Structure

| Key | Purpose |
|---|---|
| `global` | Shared defaults (namespace, image, resources, tolerations) |
| `models` | Array of model configs |
| `serverPresets` | Server-type defaults (e.g. `llamaCpp`) |
| `integrations` | External tool config (ArgoCD sync waves) |
| `mlflow` / `phoenix-helm` | Subchart values |

**Minimal model entry:**
```yaml
- name: my-model           # used directly as resource name
  enabled: true
  image:
    repository: org/image
    tag: version
  args: [llama-server, -hf, org/model]
  service:
    port: 8080
  pvc:
    storage: "50Gi"
    storageClassName: local-path
  resources:
    limits:
      memory: "50Gi"
    requests:
      memory: "30Gi"
  zeroscaling:
    enabled: true
    minReplicas: 1
  template: |
    {# Jinja2 prompt template #}
```

**Test hooks** (files in `tests/`):
```yaml
annotations:
  "helm.sh/hook": test
  "helm.sh/hook-delete-policy": hook-succeeded,hook-failed
```

## Common Tasks

**Add a model**: append entry to `models[]` in `values.yaml` with at minimum `name` and `enabled`, then run `helm template` to verify.

**Add a template**: create file in `templates/`, follow label/annotation patterns, use `$merged` for merged values, update `values.schema.json` if new config keys are introduced.

**Modify a helper**: edit `_helpers.tpl`, verify with `helm template`, preserve backward compatibility.
