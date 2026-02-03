{{/*
Chart name
*/}}
{{- define "kube-ai-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Standard labels
*/}}
{{- define "kube-ai-stack.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Model labels - call with dict "model" $model "root" $
*/}}
{{- define "kube-ai-stack.modelLabels" -}}
{{ include "kube-ai-stack.labels" .root }}
app.kubernetes.io/name: {{ .model.name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}-{{ .model.name }}
{{- end }}

{{/*
Model selector labels
*/}}
{{- define "kube-ai-stack.modelSelectorLabels" -}}
app.kubernetes.io/name: {{ .model.name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}-{{ .model.name }}
{{- end }}