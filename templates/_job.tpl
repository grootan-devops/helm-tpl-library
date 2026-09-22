{{- define "tpl.job" }}
{{- if (._container).enabled }}
{{- $sa := deepCopy .Values.serviceAccount }}
{{- if (._container).serviceAccount }}
  {{- $sa = mergeOverwrite $sa (deepCopy (._container).serviceAccount) }}
{{- end }}

{{- $jobValues := dict }}
{{- range $k, $v := .Values }}
  {{- $_ := set $jobValues $k $v }}
{{- end }}
{{- $_ := set $jobValues "serviceAccount" $sa }}

{{- $_ := set $jobValues "containers" ((._container).containers | default dict) }}
{{- $_ := set $jobValues "initContainers" ((._container).initContainers | default dict) }}
{{- $_ := set $jobValues "_workload" "job" }}
{{- $_ := set $jobValues "restartPolicy" ((._container).restartPolicy | default "OnFailure") }}
{{- $_ := set $jobValues "service" dict }}
{{- $_ := set $jobValues "autoscaling" dict }}
{{- $_ := set $jobValues "pdb" dict }}

{{- $jobContext := dict 
  "Values" $jobValues 
  "Release" .Release 
  "Chart" .Chart 
  "Template" .Template 
  "Capabilities" .Capabilities 
  "_container" ._container 
  "name" .serviceSuffix
}}

apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "tpl.resource.name" $jobContext }}
  labels:
{{ include "tpl.labels" $jobContext | indent 4 }}
  {{- if (._container).annotations }}
  annotations:
{{ toYaml (._container).annotations | indent 4 }}
  {{- end }}
spec:
{{- include "tpl.job.spec" $jobContext | nindent 2 }}
---
{{- if (._container).containers }}
{{- range $key := keys (._container).containers | sortAlpha }}
  {{- $container := get ($._container).containers $key }}
  {{- $ctx := dict "Values" $jobValues "Release" $.Release "Chart" $.Chart "Template" $.Template "Capabilities" $.Capabilities "_container" $container "_containerName" $key "_containerType" "main" "name" $jobContext.name }}
  {{- include "tpl.configmap.env" $ctx }}
---
  {{- include "tpl.secret.env" $ctx }}
---
  {{- include "tpl.secret.volume" $ctx }}
---
  {{- include "tpl.configmap.volume" $ctx }}
---
{{- end }}
{{- end }}

{{- if (._container).initContainers }}
{{- range $key := keys (._container).initContainers | sortAlpha }}
  {{- $container := get ($._container).initContainers $key }}
  {{- $ctx := dict "Values" $jobValues "Release" $.Release "Chart" $.Chart "Template" $.Template "Capabilities" $.Capabilities "_container" $container "_containerName" $key "_containerType" "init" "name" $jobContext.name }}
  {{- include "tpl.configmap.env" $ctx }}
---
  {{- include "tpl.secret.env" $ctx }}
---
  {{- include "tpl.secret.volume" $ctx }}
---
  {{- include "tpl.configmap.volume" $ctx }}
---
{{- end }}
{{- end }}

{{- include "tpl.serviceaccount" $jobContext }}
{{- end }}
{{- end }}

{{- define "tpl.jobtemplate.spec" }}
{{- if (._container).activeDeadlineSeconds }}
activeDeadlineSeconds: {{ (._container).activeDeadlineSeconds }}
{{- end }}
{{- if (._container).backoffLimit }}
backoffLimit: {{ (._container).backoffLimit }}
{{- end }}
{{- if (._container).completions }}
completions: {{ (._container).completions }}
{{- end }}
{{- if (._container).parallelism }}
parallelism: {{ (._container).parallelism }}
{{- end }}
{{- end }}

{{- define "tpl.job.spec" }}
{{- include "tpl.jobtemplate.spec" . }}
template:
  metadata:
    labels:
{{ include "tpl.labels" . | indent 6 }}
  spec: {{- include "tpl.pod.spec" . | nindent 4 }}
{{- if (._container).suspend }}
suspend: {{ (._container).suspend }}
{{- end }}
{{- if (._container).ttlSecondsAfterFinished }}
ttlSecondsAfterFinished: {{ (._container).ttlSecondsAfterFinished }}
{{- end }}
{{- end }}
