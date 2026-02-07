# kube-ai-stack

A solution inspired by the kube-prometheus stack with the intention of providing an 'all-in-one' ai platform solution. At the moment, it's geared towards [my homelab](https://docs.bhamm-lab.com/ai/), but I will continue making it as agnostic as possible. Feedback is welcome!

## Overview

kube-ai-stack provides a complete Helm-based deployment solution for running multiple LLM models in Kubernetes environments. It combines model serving, auto-scaling, monitoring, and unified API gateway capabilities into a single, manageable stack.

### Key Features

- **Multi-Model Support**: Deploy and manage multiple LLM models simultaneously
- **GPU Agnostic**: Supports gpu operators through resource requests/limists (examples with AMD)
- **Auto-scaling**: Intelligent scale-to-zero capabilities via Kube Elasti integration
- **Unified API Gateway**: LiteLLM proxy for consistent model access and routing
- **Monitoring**: Built-in Prometheus metrics and health monitoring
- **Persistent Storage**: Model caching with configurable PVC storage
- **Template Support**: Jinja2 prompt templates for model customization
- **HuggingFace Integration**: Seamless model loading from HuggingFace Hub

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                    kube-ai-stack Architecture                      │
├────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐ │
│  │   LLM Model 1   │    │   LLM Model 2   │    │   LLM Model N   │ │
│  │   Deployment    │    │   Deployment    │    │   Deployment    │ │
│  │   (GPU-enabled) │    │   (GPU-enabled) │    │   (GPU-enabled) │ │
│  └────────┬────────┘    └────────┬────────┘    └────────┬────────┘ │
│           │                      │                      │          │
│  ┌────────┴────────┐    ┌────────┴────────┐    ┌────────┴────────┐ │
│  │     Service     │    │     Service     │    │     Service     │ │
│  │   (Model API)   │    │   (Model API)   │    │   (Model API)   │ │
│  └────────┬────────┘    └────────┬────────┘    └────────┬────────┘ │
│           │                      │                      │          │
│  ┌────────┴────────┐    ┌────────┴────────┐    ┌────────┴────────┐ │
│  │   Persistent    │    │   Persistent    │    │   Persistent    │ │
│  │  Volume Claim   │    │  Volume Claim   │    │  Volume Claim   │ │
│  │  (Model Cache)  │    │  (Model Cache)  │    │  (Model Cache)  │ │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘ │
│           │                      │                      │          │
│  ┌────────┴──────────────────────┴──────────────────────┴────────┐ │
│  │                    LiteLLM Proxy/Gateway                      │ │
│  │                  (Unified API Endpoint)                       │ │
│  └───────────────────────────────────────────────────────────────┘ │
│           │                                                        │
│  ┌────────┴──────────────────────────────────────────────────────┐ │
│  │              Monitoring & Auto-scaling Layer                  │ │
│  │  ┌─────────────────┐    ┌─────────────────┐                   │ │
│  │  │  ServiceMonitor │    │  ElastiService  │                   │ │
│  │  │  (Prometheus)   │    │ (Auto-scaling)  │                   │ │
│  │  └─────────────────┘    └─────────────────┘                   │ │
│  └───────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Kubernetes cluster (v1.19+)
- GPU operators installed (for GPU workloads)
- Helm 3.x
- kubectl configured for your cluster

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd kube-ai-stack

# Install the Helm chart
helm install my-ai-stack charts/kube-ai-stack

# Or install with custom configuration
helm install my-ai-stack charts/kube-ai-stack -f my-values.yaml
```

### Verify Installation

```bash
# Check deployment status
kubectl get deployments -n models

# Check services
kubectl get services -n models

# Check pod status
kubectl get pods -n models
```

## Project Structure

```
kube-ai-stack/
├── charts/
│   └── kube-ai-stack/          # Main Helm chart
│       ├── templates/          # Kubernetes manifests
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── pvc.yaml
│       │   ├── litellm-configmap.yaml
│       │   ├── servicemonitor.yaml
│       │   ├── elastiservice.yaml
│       │   └── prompt-template-configmap.yaml
│       ├── values.yaml         # Default configuration
│       ├── values.schema.json  # Configuration schema
│       └── README.md          # Chart-specific documentation
├── LICENSE                    # BSD 3-Clause License
└── README.md                  # This file
```

## Core Components

### Model Deployments
- **Container**: Examples with AMD-optimized images for llama.cpp server
- **GPU Support**: Native GPU resource allocation
- **Health Monitoring**: Built-in health checks and readiness probes
- **Resource Management**: Configurable CPU, memory, and GPU limits

### LiteLLM Integration
- **Unified API**: Single endpoint for all model interactions with templated configmap
- **Load Balancing**: Intelligent request routing across model instances
- **Caching**: Optional semantic caching for improved performance
- **Monitoring**: Request tracking and performance metrics

### Auto-scaling
- **Scale-to-Zero**: Automatic scaling based on request load
- **Prometheus Integration**: Metrics-driven scaling decisions
- **Configurable Triggers**: Custom scaling thresholds and cooldown periods
- **Resource Optimization**: Efficient GPU utilization

### Storage Management
- **Persistent Volumes**: Model caching for faster startup times
- **Storage Classes**: Flexible storage configuration
- **Size Management**: Configurable storage allocation per model

## Configuration

The stack is highly configurable through Helm values. Key configuration areas include:

- **Global Settings**: Namespace, image repository, resource defaults
- **Model Definitions**: Individual model configurations and parameters
- **LiteLLM Settings**: Gateway configuration and routing behavior
- **Auto-scaling**: Scaling policies and trigger conditions
- **Resource Management**: CPU, memory, and GPU allocation
- **Storage**: PVC configuration and storage class selection

For detailed configuration options, see the [chart README](charts/kube-ai-stack/README.md).

## Use Cases

### Homelab
- This is what it was originally tested for!
- Enables testing the latest OSS models and quickly have them available in LiteLLM gateway
- Scale-to-zero to enable multiple models on limited hardware

### Dev Clusters and Experimentation
- Clusters in lower environments used by MLE/AI Engineers
- Ability to quickly test 
- Scale-to-zero enabled for cost effectiveness in off-hours.

### Production
- At the moment, I wouldn't necessarily recommend this
- However, in theory, with kube elasti scaling disabled, this is feasible. Or if you can handle cold start latency, this could work

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Check the [chart documentation](charts/kube-ai-stack/README.md) for detailed configuration
- Review the architecture diagram and component descriptions
- Submit issues for bugs or feature requests

---

**Note**: This is a Kubernetes-native solution designed for production environments. Ensure your cluster has the necessary GPU operators and resources before deployment.