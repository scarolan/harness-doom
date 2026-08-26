{{- define "doom-gate.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "doom-gate.labels" -}}
app.kubernetes.io/name: doom-gate
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "doom-gate.selectorLabels" -}}
app.kubernetes.io/name: doom-gate
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
