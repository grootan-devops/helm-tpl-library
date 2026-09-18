{{- define "tpl.networkpolicy" }}
{{- if .Values.networkPolicy.enabled }}
{{- if or (.Values.networkPolicy.egressRule) (.Values.networkPolicy.ingressRule) }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "tpl.resource.name" . }}
  labels: {{- include "tpl.labels" . | nindent 4 }}  
spec:
  podSelector:
    matchLabels: {{- include "tpl.selectorLabels" . | nindent 6 }} 
  policyTypes: 
  {{- if .Values.networkPolicy.ingressRule }}
    - Ingress
  {{- end }}
  {{- if .Values.networkPolicy.egressRule }}
    - Egress
  {{- end }}
  ingress: {{- toYaml .Values.networkPolicy.ingressRule | nindent 4 }}
  egress: {{- toYaml .Values.networkPolicy.egressRule | nindent 4 }}
{{- end }}
{{- end }}
{{- end }}
