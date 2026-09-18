{{- define "tpl.configmap.env" }}
{{- if or (._container).configmapEnvs (._container).additionalConfigmapEnvs }}
{{- $envSuffix := printf "%s-env" ._containerName }}
{{- if .name }}
  {{- if eq .name ._containerName }}
    {{- $envSuffix = printf "%s-env" .name }}
  {{- else }}
    {{- $envSuffix = printf "%s-%s-env" .name ._containerName }}
  {{- end }}
{{- end }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "tpl.resource.name" (dict "name" $envSuffix "Release" $.Release "Values" $.Values) }}
  labels: {{- include "tpl.labels" . | nindent 4 }}
data:
{{- $baseRaw := "" }}
{{- if kindIs "string" (._container).configmapEnvs }}
  {{- $baseRaw = tpl ((._container).configmapEnvs | default "") $ }}
{{- else }}
  {{- $baseRaw = tpl ((._container).configmapEnvs | default dict | toYaml) $ }}
{{- end }}
{{- $base := fromYaml $baseRaw | default dict }}
{{- $additional := (._container).additionalConfigmapEnvs | default dict }}
{{- $merged := merge (deepCopy $additional) $base }}
{{- range $k, $v := $merged }}
  {{- if ne $v "" }}
  {{ $k }}: {{ tpl ($v | toString) $ | quote }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "tpl.configmap.volume" }}
{{- range $key, $val := .Values.mounts.configmap }}
{{- $rawMountTo := $val.mountTo | default "both" }}
{{- $mountList := list }}
{{- if kindIs "slice" $rawMountTo }}
  {{- range $m := $rawMountTo }}
    {{- $mountList = append $mountList (tpl $m $) }}
  {{- end }}
{{- else }}
  {{- $mountList = list (tpl $rawMountTo $) }}
{{- end }}
{{- $containerName := include "tpl.container.name" $ }}

{{- if include "tpl.strToBool" (tpl ($val.enabled | toString | default "true") $) }}
{{- if or (has "both" $mountList) (has $._containerType $mountList) (has $containerName $mountList) (has $._containerName $mountList) }}
  {{- $volName := printf "%s-%s-%s" (include "tpl.resource.name" $) $._containerName $key }}
  {{- if and $.name (eq $.name $._containerName) }}
    {{- $volName = printf "%s-%s" (include "tpl.resource.name" $) $key }}
  {{- end }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $volName }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
data:
{{- if kindIs "string" $val.data }}
{{ tpl $val.data $ | indent 2 }}
{{- else }}
{{- range $dk, $dv := $val.data }}
  {{ $dk }}: |-
{{ tpl ($dv | toString) $ | indent 4 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
---
{{- end }}
{{- end }}