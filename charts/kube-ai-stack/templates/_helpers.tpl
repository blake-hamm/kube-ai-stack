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
{{ include "kube-ai-stack.name" . }}
app.kubernetes.io/version: {{ .Chart.Version | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: kube-ai-stack
{{- end }}

{{/*
Component labels - for use with specific components
*/}}
{{- define "kube-ai-stack.componentLabels" -}}
{{ include "kube-ai-stack.labels" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ .component | default "default" }}
{{- end }}

{{/*
Model labels - call with dict "model" $model "root" $
*/}}
{{- define "kube-ai-stack.modelLabels" -}}
{{ include "kube-ai-stack.labels" .root }}
app.kubernetes.io/name: {{ .model.name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}-{{ .model.name }}
app.kubernetes.io/component: model
{{- end }}

{{/*
Model selector labels
*/}}
{{- define "kube-ai-stack.modelSelectorLabels" -}}
app.kubernetes.io/name: {{ .model.name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}-{{ .model.name }}
{{- end }}

{{/*
Service labels
*/}}
{{- define "kube-ai-stack.serviceLabels" -}}
{{ include "kube-ai-stack.labels" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: service
{{- end }}

{{/*
PVC labels
*/}}
{{- define "kube-ai-stack.pvcLabels" -}}
{{ include "kube-ai-stack.labels" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: storage
{{- end }}

{{/*
ConfigMap labels
*/}}
{{- define "kube-ai-stack.configMapLabels" -}}
{{ include "kube-ai-stack.labels" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: config
{{- end }}