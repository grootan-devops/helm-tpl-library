{{- define "tpl.labels" -}}
helm.sh/chart: {{ include "tpl.chart" . }}
{{ include "tpl.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.global.partOf }}
app.kubernetes.io/part-of: {{ .Values.global.partOf }}
{{- end }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/component: {{ include "tpl.component.name" $ }}
{{- with .Values.global.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "tpl.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tpl.resource.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .service }}
{{- if .serviceSuffix }}
app.kubernetes.io/service: {{ .service }}-{{ .serviceSuffix }}
{{- else }}
app.kubernetes.io/service: {{ .service }}
{{- end }}
{{- else }}
{{- if .serviceSuffix }}
app.kubernetes.io/service: {{ include "tpl.resource.name" . }}-{{ .serviceSuffix }}
{{- else }}
app.kubernetes.io/service: {{ include "tpl.resource.name" . }}
{{- end }}
{{- end }}
{{- end }}
