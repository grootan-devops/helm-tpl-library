{{- define "tpl.servicemonitor" }}
{{- if and .Values.global.metrics.enabled .Values.metrics.endpoints }}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: {{ include "tpl.resource.name" . }}
  labels:
    {{- include "tpl.labels" . | nindent 4 }}
    {{- with .Values.global.metrics.additionalLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  endpoints: {{- .Values.metrics.endpoints | toYaml | nindent 4 }}
  namespaceSelector:
    matchNames:
      - {{ .Release.Namespace }}
  jobLabel: {{ .Values.metrics.jobLabel }}
  selector:
    matchLabels: {{- include "tpl.selectorLabels" . | nindent 6 }}
{{- end }}
{{- end }}

{{- define "tpl.podmonitor" }}
{{- if and .Values.global.metrics.enabled .Values.metrics.endpoints }}
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: {{ include "tpl.resource.name" . }}
  labels:
    {{- include "tpl.labels" . | nindent 4 }}
    {{- with .Values.global.metrics.additionalLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  podMetricsEndpoints: {{- .Values.metrics.endpoints | toYaml | nindent 4 }}
  namespaceSelector:
    matchNames:
      - {{ .Release.Namespace }}
  jobLabel: {{ .Values.metrics.jobLabel }}
  selector:
    matchLabels: {{- include "tpl.selectorLabels" . | nindent 6 }}
{{- end }}
{{- end }}
