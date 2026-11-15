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
  labels:
    {{- include "tpl.labels" $ | nindent 4 }}
    {{- with .labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- $wpSvc := include "tpl.mesh.waypoint.serviceLabels" $ | trim }}
    {{- if $wpSvc }}
    {{- $wpSvc | nindent 4 }}
    {{- end }}
  annotations: {{- .annotations | toYaml | nindent 4 }}
spec:
  selector: {{- include "tpl.selectorLabels" $ | nindent 4 }}
  {{- .spec | toYaml | nindent 2 }}
---
{{- end }}
{{- end }}
