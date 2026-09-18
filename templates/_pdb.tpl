{{- define "tpl.pdb" }}
{{- if .Values.pdb.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "tpl.resource.name" . }}
  labels: {{- include "tpl.labels" . | nindent 4 }}
spec:
  {{- if .Values.pdb.minAvailable }}
  minAvailable: {{ .Values.pdb.minAvailable }}
  {{- else }}
  maxUnavailable: {{ .Values.pdb.maxUnavailable }}
  {{- end }}
  selector:
    matchLabels: {{- include "tpl.selectorLabels" . | nindent 6 }} 
{{- end }}
{{- end }}
