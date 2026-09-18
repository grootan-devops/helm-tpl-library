{{- define "tpl.service" }}
{{- range $k, $v := .Values.service }}
apiVersion: v1
kind: Service
metadata:
  {{- if eq $k "default" }}
  name: {{ include "tpl.resource.name" $ }}
  {{- else }}
  name: {{ include "tpl.resource.name" (merge (dict "name" $k) $) }}
  {{- end }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
  annotations: {{- .annotations | toYaml | nindent 4 }}
spec:
  selector: {{- include "tpl.selectorLabels" $ | nindent 4 }}
  {{- .spec | toYaml | nindent 2 }}
---
{{- end }}
{{- end }}
