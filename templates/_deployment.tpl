{{- define "tpl.deployment" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "tpl.resource.name" . }}
  labels: {{- include "tpl.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels: {{- include "tpl.selectorLabels" . | nindent 6 }}
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicas }}
  {{- end }}
  revisionHistoryLimit: {{ .Values.revisionHistoryLimit }}
  strategy: {{- toYaml .Values.strategy | nindent 4 }}
  template:
    metadata:
      annotations:
        {{- range $name, $container := .Values.containers }}
        {{- $cmBaseRaw := "" }}
        {{- if kindIs "string" $container.configmapEnvs }}
          {{- $cmBaseRaw = tpl ($container.configmapEnvs | default "") $ }}
        {{- else }}
          {{- $cmBaseRaw = tpl ($container.configmapEnvs | default dict | toYaml) $ }}
        {{- end }}
        {{- $cmBase := fromYaml $cmBaseRaw | default dict }}
        {{- $cmAdd := $container.additionalConfigmapEnvs | default dict }}
        checksum/configmap-{{ $name }}-env: {{ merge $cmAdd $cmBase | toYaml | sha256sum }}

        {{- $secBaseRaw := "" }}
        {{- if kindIs "string" $container.secretEnvs }}
          {{- $secBaseRaw = tpl ($container.secretEnvs | default "") $ }}
        {{- else }}
          {{- $secBaseRaw = tpl ($container.secretEnvs | default dict | toYaml) $ }}
        {{- end }}
        {{- $secBase := fromYaml $secBaseRaw | default dict }}
        {{- $secAdd := $container.additionalSecretEnvs | default dict }}
        checksum/secret-{{ $name }}-env: {{ merge $secAdd $secBase | toYaml | sha256sum }}
        {{- end }}

        {{- range $name, $container := .Values.initContainers }}
        {{- $cmBaseRaw := "" }}
        {{- if kindIs "string" $container.configmapEnvs }}
          {{- $cmBaseRaw = tpl ($container.configmapEnvs | default "") $ }}
        {{- else }}
          {{- $cmBaseRaw = tpl ($container.configmapEnvs | default dict | toYaml) $ }}
        {{- end }}
        {{- $cmBase := fromYaml $cmBaseRaw | default dict }}
        {{- $cmAdd := $container.additionalConfigmapEnvs | default dict }}
        checksum/configmap-init-{{ $name }}-env: {{ merge $cmAdd $cmBase | toYaml | sha256sum }}

        {{- $secBaseRaw := "" }}
        {{- if kindIs "string" $container.secretEnvs }}
          {{- $secBaseRaw = tpl ($container.secretEnvs | default "") $ }}
        {{- else }}
          {{- $secBaseRaw = tpl ($container.secretEnvs | default dict | toYaml) $ }}
        {{- end }}
        {{- $secBase := fromYaml $secBaseRaw | default dict }}
        {{- $secAdd := $container.additionalSecretEnvs | default dict }}
        checksum/secret-init-{{ $name }}-env: {{ merge $secAdd $secBase | toYaml | sha256sum }}
        {{- end }}

        {{- if .Values.mounts }}
        checksum/mounts: {{ tpl (.Values.mounts | toYaml) $ | sha256sum }}
        {{- end }}
        {{- if .Values.pod.annotations }}
        {{ .Values.pod.annotations | toYaml | nindent 8 }}
        {{- end }}
      labels: {{- include "tpl.labels" . | nindent 8 }}
    spec: {{- include "tpl.pod.spec" (merge (dict "_container" .Values) $) | nindent 6 }}
---
{{- include "tpl.service" . }}
---
{{- range $key := keys .Values.containers | sortAlpha }}
  {{- $container := get $.Values.containers $key }}
  {{- include "tpl.configmap.env" (merge (dict "_container" $container "_containerName" $key "_containerType" "main") $) }}
---
  {{- include "tpl.secret.env" (merge (dict "_container" $container "_containerName" $key "_containerType" "main") $) }}
---
  {{- include "tpl.secret.volume" (merge (dict "_container" $container "_containerName" $key "_containerType" "main") $) }}
---
  {{- include "tpl.configmap.volume" (merge (dict "_container" $container "_containerName" $key "_containerType" "main") $) }}
---
{{- end }}
{{- range $key := keys .Values.initContainers | sortAlpha }}
  {{- $container := get $.Values.initContainers $key }}
  {{- include "tpl.configmap.env" (merge (dict "_container" $container "_containerName" $key "_containerType" "init") $) }}
---
  {{- include "tpl.secret.env" (merge (dict "_container" $container "_containerName" $key "_containerType" "init") $) }}
---
  {{- include "tpl.secret.volume" (merge (dict "_container" $container "_containerName" $key "_containerType" "init") $) }}
---
  {{- include "tpl.configmap.volume" (merge (dict "_container" $container "_containerName" $key "_containerType" "init") $) }}
---
{{- end }}
---
{{- include "tpl.routes" . }}
---
{{ include "tpl.serviceaccount" . }}
---
{{ include "tpl.pdb" . }}
---
{{ include "tpl.networkpolicy" . }}
---
{{ include "tpl.hpa" . }}
---
{{- end }}
