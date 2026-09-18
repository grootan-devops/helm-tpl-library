{{- define "tpl.secret.env" }}
{{- if or (._container).secretEnvs (._container).additionalSecretEnvs }}
{{- $envSuffix := printf "%s-env" ._containerName }}
{{- if .name }}
  {{- if eq .name ._containerName }}
    {{- $envSuffix = printf "%s-env" .name }}
  {{- else }}
    {{- $envSuffix = printf "%s-%s-env" .name ._containerName }}
  {{- end }}
{{- end }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "tpl.resource.name" (dict "name" $envSuffix "Release" $.Release "Values" $.Values) }}
  labels: {{- include "tpl.labels" . | nindent 4 }}
type: Opaque
data:
{{- $baseRaw := "" }}
{{- if kindIs "string" (._container).secretEnvs }}
  {{- $baseRaw = tpl ((._container).secretEnvs | default "") $ }}
{{- else }}
  {{- $baseRaw = tpl ((._container).secretEnvs | default dict | toYaml) $ }}
{{- end }}
{{- $base := fromYaml $baseRaw | default dict }}
{{- $additional := (._container).additionalSecretEnvs | default dict }}
{{- $merged := merge (deepCopy $additional) $base }}
{{- range $k, $v := $merged }}
  {{- if ne $v "" }}
  {{ $k }}: {{ tpl ($v | toString) $ | b64enc | quote }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "tpl.secret.volume" }}
{{- range $key, $val := .Values.mounts.secret }}
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
kind: Secret
metadata:
  name: {{ $volName }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
type: Opaque
{{- if $val.stringData }}
stringData:
{{- if kindIs "string" $val.stringData }}
{{ tpl $val.stringData $ | indent 2 }}
{{- else }}
{{- range $dk, $dv := $val.stringData }}
  {{ $dk }}: |-
{{ tpl ($dv | toString) $ | indent 4 }}
{{- end }}
{{- end }}
{{- end }}
{{- if $val.data }}
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
{{- end }}
---
{{- end }}
{{- end }}
