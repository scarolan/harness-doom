{{- define "harness-doom.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "harness-doom.labels" -}}
app.kubernetes.io/name: harness-doom
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "harness-doom.selectorLabels" -}}
app.kubernetes.io/name: harness-doom
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
