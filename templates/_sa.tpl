{{- define "tpl.serviceaccount" }}
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "tpl.resource.name" . }}
  labels: {{- include "tpl.labels" . | nindent 4 }}
  annotations: {{- toYaml .Values.serviceAccount.annotations | nindent 4 }}
secrets:
  - name: {{ include "tpl.resource.token.name" . }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "tpl.resource.token.name" . }}
  labels: {{- include "tpl.labels" . | nindent 4 }}
  annotations:
    kubernetes.io/service-account.name: {{ include "tpl.resource.name" . }}
type: kubernetes.io/service-account-token
{{- end }}
{{- end }}
