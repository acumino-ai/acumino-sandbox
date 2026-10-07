{{- define "telemetry-signer.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "telemetry-signer.labels" -}}
app.kubernetes.io/name: telemetry-signer
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "telemetry-signer.selectorLabels" -}}
app.kubernetes.io/name: telemetry-signer
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
