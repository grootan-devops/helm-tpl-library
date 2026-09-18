{{- define "tpl.rbac.role" }}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "tpl.resource.name" . }}
  labels: {{- include "tpl.labels" . | nindent 4 }}
{{- end }}

{{- define "tpl.rbac.rolebinding" }}
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: {{ include "tpl.resource.name" . }}
  labels: {{- include "tpl.labels" . | nindent 4 }}
subjects:
  - kind: ServiceAccount
    name: {{ include "tpl.resource.name" . }}
    apiGroup: ""
roleRef:
  kind: Role
  name: {{ include "tpl.resource.name" . }}
  apiGroup: ""
{{- end }}

{{- define "tpl.rbac.clusterrole" }}
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: {{ include "tpl.resource.name" . }}-{{ .Release.Namespace }} 
  labels: {{- include "tpl.labels" . | nindent 4 }}
{{- end }}

{{- define "tpl.rbac.clusterrolebinding" }}
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: {{ include "tpl.resource.name" . }}-{{ .Release.Namespace }} 
  labels: {{- include "tpl.labels" . | nindent 4 }}
subjects:
  - kind: ServiceAccount
    name: {{ include "tpl.resource.name" . }}
    namespace: {{ .Release.Namespace }}
roleRef:
  kind: ClusterRole
  name: {{ include "tpl.resource.name" . }}-{{ .Release.Namespace }} 
  apiGroup: ""
{{- end }}
