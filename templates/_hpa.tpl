{{- define "tpl.hpa" }}
{{- if and .Values.autoscaling.enabled .Values.autoscaling.metrics }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "tpl.resource.name" . }}
  labels: {{- include "tpl.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "tpl.resource.name" . }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}
  metrics: {{- toYaml .Values.autoscaling.metrics | nindent 4 }}
  {{- if or (.Values.autoscaling.scaleUp) (.Values.autoscaling.scaleDown) }}
  behavior:
    {{- if .Values.autoscaling.scaleUp }}
    scaleUp: {{- toYaml .Values.autoscaling.scaleUp | nindent 6 }}
    {{- end }}
    {{- if .Values.autoscaling.scaleDown }}
    scaleDown: {{- toYaml .Values.autoscaling.scaleDown | nindent 6 }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
