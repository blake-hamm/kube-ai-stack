# kube-ai-stack Helm Chart

A Helm chart for deploying LLM model backends with LiteLLM integration on Kubernetes.

## Description

This chart deploys multiple LLM models as Kubernetes Deployments with:
- GPU support (AMD GPU via amd.com/gpu resource)
- Persistent storage for model caching
- Health checks and readiness probes
- Prometheus metrics endpoints
- Optional scale-to-zero via Kube Elasti
- LiteLLM proxy configuration for llm gateway
- Optional MLflow integration for experiment tracking and model registry
- Optional Phoenix (Arize) integration for ML observability and tracing

## Installation

### Prerequisites

- Kubernetes cluster (v1.19+)
- AMD GPU operators (for GPU workloads)
- Prometheus Operator (optional, for ServiceMonitor)
- ElastiService operator (optional, for auto-scaling)

### Install the chart

```bash
# Install the chart with default values
helm install my-release charts/kube-ai-stack

# Install with custom values
helm install my-release charts/kube-ai-stack -f my-values.yaml

# Upgrade an existing release
helm upgrade my-release charts/kube-ai-stack -f my-values.yaml
```

### Uninstall the chart

```bash
helm uninstall my-release
```

## Configuration

The following table lists the configurable parameters of the kube-ai-stack chart and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Namespace for model deployments | `models` |
| `global.prometheusUrl` | Prometheus server URL | `http://prometheus-server.monitoring.svc.cluster.local:9090` |
| `global.litellmNamespace` | Namespace for LiteLLM config | `litellm` |
| `global.image.repository` | Default container image repository | `kyuz0/amd-strix-halo-toolboxes` |
| `global.image.tag` | Default container image tag | `vulkan-radv` |
| `global.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `global.service.port` | Default service port | `8080` |
| `global.pvc.storageClassName` | Storage class for PVCs | `local-path` |
| `global.pvc.storage` | Default storage size | `10Gi` |

### Observability Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.mlflow.enabled` | Enable MLflow deployment | `false` |
| `global.phoenix.enabled` | Enable Phoenix deployment | `false` |

### LiteLLM Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.litellm.manage_config` | Auto-generate LiteLLM config | `true` |
| `global.litellm.config.litellm_settings.timeout` | Request timeout | `1800` |
| `global.litellm.config.litellm_settings.stream_timeout` | Stream timeout | `1800` |
| `global.litellm.config.litellm_settings.cache` | Enable caching | `false` |
| `global.litellm.config.general_settings.max_parallel_requests` | Max parallel requests | `5` |
| `global.litellm.config.router_settings.debug_level` | Debug level | `INFO` |
| `global.litellm.config.router_settings.routing_strategy` | Routing strategy | `simple-shuffle` |

### Auto-scaling Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.zeroscaling.enabled` | Enable auto-scaling | `true` |
| `global.zeroscaling.minReplicas` | Minimum replicas | `1` |
| `global.zeroscaling.cooldownPeriod` | Cooldown period (seconds) | `1800` |
| `global.zeroscaling.trigger.query` | Prometheus query | See values.yaml |
| `global.zeroscaling.trigger.threshold` | Scaling threshold | `1` |

### Resource Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.resources.limits.amd.com/gpu` | GPU limit | `1` |
| `global.resources.limits.memory` | Memory limit | `50Gi` |
| `global.resources.limits.cpu` | CPU limit | `4` |
| `global.resources.requests.amd.com/gpu` | GPU request | `1` |
| `global.resources.requests.memory` | Memory request | `30Gi` |
| `global.resources.requests.cpu` | CPU request | `1` |

### Model Configuration

Each model in `global.models` array supports:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `name` | Model name (required) | - |
| `enabled` | Enable model deployment | `true` |
| `description` | Model description | - |
| `image.repository` | Container image repository | Global default |
| `image.tag` | Container image tag | Global default |
| `pvc.storage` | PVC storage size | Global default |
| `pvc.storageClassName` | PVC storage class | Global default |
| `service.port` | Service port | Global default |
| `args` | Container command arguments | - |
| `template` | Jinja2 prompt template | - |
| `litellm_params` | LiteLLM parameters | - |

## Example Values

### Basic Single Model

```yaml
global:
  namespace: llm-models
  image:
    repository: kyuz0/amd-strix-halo-toolboxes
    tag: vulkan-radv
  models:
    - name: llama3-8b
      enabled: true
      description: "Llama 3 8B model"
      args:
        - llama-server
        - -hf
        - meta-llama/Llama-3-8B-Instruct
        - --host
        - 0.0.0.0
        - --metrics
        - --no-webui
      resources:
        limits:
          amd.com/gpu: 1
          memory: "40Gi"
          cpu: "4"
        requests:
          amd.com/gpu: 1
          memory: "30Gi"
          cpu: "2"
```

### Multiple Models with Custom Templates

```yaml
global:
  namespace: llm-models
  image:
    repository: kyuz0/amd-strix-halo-toolboxes
    tag: vulkan-amdvlk
  models:
    - name: llama3-70b
      enabled: true
      description: "Llama 3 70B model"
      pvc:
        storage: "100Gi"
      args:
        - llama-server
        - -hf
        - meta-llama/Llama-3-70B-Instruct
        - -ngl
        - "999"
        - --host
        - 0.0.0.0
        - --metrics
      resources:
        limits:
          amd.com/gpu: 1
          memory: "100Gi"
          cpu: "8"
        requests:
          amd.com/gpu: 1
          memory: "70Gi"
          cpu: "4"
      template: |
        {%- if tools %}
        <|im_start|>system
        You are a helpful assistant with access to tools.
        <|im_end|>
        {%- endif %}
        {%- for message in messages %}
        <|im_start|>{{ message.role }}
        {{ message.content }}<|im_end|>
        {%- endfor %}
        {%- if messages[-1]['role'] == 'user' %}
        <|im_start|>assistant
        {%- endif %}
```

### With HuggingFace Token

```yaml
global:
  namespace: llm-models
  hfToken:
    enabled: true
    secretName: hf-token-secret
    secretKey: token
  models:
    - name: mistral-7b
      enabled: true
      args:
        - llama-server
        - -hf
        - mistralai/Mistral-7B-Instruct-v0.1
        - --host
        - 0.0.0.0
```

### With MLflow and Phoenix Enabled

```yaml
global:
  namespace: llm-models
  mlflow:
    enabled: true
  phoenix:
    enabled: true
  litellm:
    manage_config: true
    config:
      litellm_settings:
        callbacks: ["arize_phoenix"]
        success_callback: ["mlflow"]
        failure_callback: ["mlflow"]
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    kube-ai-stack                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │
│  │   Model 1   │    │   Model 2   │    │   Model N   │     │
│  │ Deployment  │    │ Deployment  │    │ Deployment  │     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         │                  │                  │             │
│  ┌──────┴──────┐    ┌──────┴──────┐    ┌──────┴──────┐     │
│  │   Service   │    │   Service   │    │   Service   │     │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │
│         │                  │                  │             │
│  ┌──────┴──────┐    ┌──────┴──────┐    ┌──────┴──────┐     │
│  │     PVC     │    │     PVC     │    │     PVC     │     │
│  └─────────────┘    └─────────────┘    └─────────────┘     │
│         │                  │                  │             │
│  ┌──────┴──────────────────┴──────────────────┴──────┐     │
│  │              ServiceMonitor (Prometheus)           │     │
│  └────────────────────────────────────────────────────┘     │
│         │                  │                  │             │
│  ┌──────┴──────────────────┴──────────────────┴──────┐     │
│  │              ElastiService (Auto-scaling)          │     │
│  └────────────────────────────────────────────────────┘     │
│         │                                                   │
│  ┌──────┴───────────────────────────────────────────┐      │
│  │              LiteLLM ConfigMap                    │      │
│  └───────────────────────────────────────────────────┘      │
│         │                                                   │
│  ┌──────┴───────────────────────────────────────────┐      │
│  │              MLflow (Optional)                   │      │
│  │         Experiment Tracking & Registry           │      │
│  └───────────────────────────────────────────────────┘      │
│         │                                                   │
│  ┌──────┴───────────────────────────────────────────┐      │
│  │              Phoenix (Optional)                  │      │
│  │         ML Observability & Tracing               │      │
│  └───────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```
