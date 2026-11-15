{{- define "tpl.keda.secret" }}
{{- if and .Values.autoscaling.enabled (and .Values.autoscaling.keda .Values.autoscaling.keda.enabled) }}
{{- $authList := list }}
{{- if .Values.autoscaling.keda.triggerAuthentications }}
  {{- if kindIs "slice" .Values.autoscaling.keda.triggerAuthentications }}
    {{- $authList = .Values.autoscaling.keda.triggerAuthentications }}
  {{- else if kindIs "map" .Values.autoscaling.keda.triggerAuthentications }}
    {{- range $k, $v := .Values.autoscaling.keda.triggerAuthentications }}
      {{- $item := merge (dict "name" $k) (deepCopy $v) }}
      {{- $authList = append $authList $item }}
    {{- end }}
  {{- end }}
{{- else if .Values.autoscaling.keda.triggerAuthentication }}
  {{- $authList = list .Values.autoscaling.keda.triggerAuthentication }}
{{- end }}
{{- range $item := $authList }}
{{- if and $item.secret $item.secret.create }}
{{- $secName := "" }}
{{- if and $item.secret.name $item.secret.rawName }}
  {{- $secName = $item.secret.name }}
{{- else if $item.secret.name }}
  {{- $secName = include "tpl.resource.name" (merge (dict "name" $item.secret.name) $) }}
{{- else if $item.name }}
  {{- $secName = include "tpl.resource.name" (merge (dict "name" (printf "%s-secret" $item.name)) $) }}
{{- else }}
  {{- $secName = include "tpl.resource.name" (merge (dict "name" "keda-auth-secret") $) }}
{{- end }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ $secName }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
type: {{ $item.secret.type | default "Opaque" }}
{{- if $item.secret.data }}
data:
  {{- range $k, $v := $item.secret.data }}
  {{ $k }}: {{ tpl ($v | toString) $ | b64enc | quote }}
  {{- end }}
{{- end }}
{{- if $item.secret.stringData }}
stringData:
  {{- range $k, $v := $item.secret.stringData }}
  {{ $k }}: {{ tpl ($v | toString) $ | quote }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "tpl.keda.triggerauthentication" }}
{{- if and .Values.autoscaling.enabled (and .Values.autoscaling.keda .Values.autoscaling.keda.enabled) }}
{{- $authList := list }}
{{- if .Values.autoscaling.keda.triggerAuthentications }}
  {{- if kindIs "slice" .Values.autoscaling.keda.triggerAuthentications }}
    {{- $authList = .Values.autoscaling.keda.triggerAuthentications }}
  {{- else if kindIs "map" .Values.autoscaling.keda.triggerAuthentications }}
    {{- range $k, $v := .Values.autoscaling.keda.triggerAuthentications }}
      {{- $item := merge (dict "name" $k) (deepCopy $v) }}
      {{- $authList = append $authList $item }}
    {{- end }}
  {{- end }}
{{- else if .Values.autoscaling.keda.triggerAuthentication }}
  {{- $authList = list .Values.autoscaling.keda.triggerAuthentication }}
{{- end }}
{{- range $item := $authList }}
{{- $authName := "" }}
{{- if $item.name }}
  {{- if $item.rawName }}
    {{- $authName = $item.name }}
  {{- else }}
    {{- $authName = include "tpl.resource.name" (merge (dict "name" $item.name) $) }}
  {{- end }}
{{- else }}
  {{- $authName = include "tpl.resource.name" $ }}
{{- end }}
{{- $secName := "" }}
{{- if and $item.secret $item.secret.create }}
  {{- if and $item.secret.name $item.secret.rawName }}
    {{- $secName = $item.secret.name }}
  {{- else if $item.secret.name }}
    {{- $secName = include "tpl.resource.name" (merge (dict "name" $item.secret.name) $) }}
  {{- else if $item.name }}
    {{- $secName = include "tpl.resource.name" (merge (dict "name" (printf "%s-secret" $item.name)) $) }}
  {{- else }}
    {{- $secName = include "tpl.resource.name" (merge (dict "name" "keda-auth-secret") $) }}
  {{- end }}
{{- end }}
---
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: {{ $authName }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
  {{- with $item.annotations }}
  annotations: {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if $item.podIdentity }}
  podIdentity: {{- toYaml $item.podIdentity | nindent 4 }}
  {{- end }}
  {{- if $item.secretTargetRef }}
  secretTargetRef:
    {{- range $ref := $item.secretTargetRef }}
    - parameter: {{ $ref.parameter }}
      name: {{ default $secName $ref.name }}
      key: {{ $ref.key }}
    {{- end }}
  {{- end }}
  {{- if $item.env }}
  env: {{- toYaml $item.env | nindent 4 }}
  {{- end }}
  {{- if $item.hashiVault }}
  hashiVault: {{- toYaml $item.hashiVault | nindent 4 }}
  {{- end }}
  {{- if $item.azureKeyVault }}
  azureKeyVault: {{- toYaml $item.azureKeyVault | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "tpl.keda.scaledobject" }}
{{- if and .Values.autoscaling.enabled (and .Values.autoscaling.keda .Values.autoscaling.keda.enabled) }}
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: {{ include "tpl.resource.name" . }}
  labels: {{- include "tpl.labels" . | nindent 4 }}
  {{- with .Values.autoscaling.keda.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "tpl.resource.name" . }}
  {{- if and (hasKey .Values.autoscaling.keda "minReplicaCount") (ne (toString .Values.autoscaling.keda.minReplicaCount) "<nil>") (ne (toString .Values.autoscaling.keda.minReplicaCount) "") }}
  minReplicaCount: {{ .Values.autoscaling.keda.minReplicaCount }}
  {{- else if and (hasKey .Values.autoscaling "minReplicas") (ne (toString .Values.autoscaling.minReplicas) "<nil>") (ne (toString .Values.autoscaling.minReplicas) "") }}
  minReplicaCount: {{ .Values.autoscaling.minReplicas }}
  {{- end }}
  maxReplicaCount: {{ default .Values.autoscaling.maxReplicas .Values.autoscaling.keda.maxReplicaCount }}
  {{- if .Values.autoscaling.keda.pollingInterval }}
  pollingInterval: {{ .Values.autoscaling.keda.pollingInterval }}
  {{- end }}
  {{- if .Values.autoscaling.keda.cooldownPeriod }}
  cooldownPeriod: {{ .Values.autoscaling.keda.cooldownPeriod }}
  {{- end }}
  {{- if and (hasKey .Values.autoscaling.keda "idleReplicaCount") (ne (toString .Values.autoscaling.keda.idleReplicaCount) "<nil>") (ne (toString .Values.autoscaling.keda.idleReplicaCount) "") }}
  idleReplicaCount: {{ .Values.autoscaling.keda.idleReplicaCount }}
  {{- end }}
  {{- with .Values.autoscaling.keda.fallback }}
  fallback:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- $behavior := dict }}
  {{- if .Values.autoscaling.scaleUp }}
    {{- $_ := set $behavior "scaleUp" .Values.autoscaling.scaleUp }}
  {{- end }}
  {{- if .Values.autoscaling.scaleDown }}
    {{- $_ := set $behavior "scaleDown" .Values.autoscaling.scaleDown }}
  {{- end }}
  {{- $hpaConfig := dict }}
  {{- if $behavior }}
    {{- $_ := set $hpaConfig "behavior" $behavior }}
  {{- end }}
  {{- $advanced := deepCopy (.Values.autoscaling.keda.advanced | default dict) }}
  {{- if $hpaConfig }}
    {{- $existingHpa := get $advanced "horizontalPodAutoscalerConfig" | default dict }}
    {{- $_ := set $advanced "horizontalPodAutoscalerConfig" (mergeOverwrite $hpaConfig $existingHpa) }}
  {{- end }}
  {{- with $advanced }}
  advanced:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if .Values.autoscaling.keda.triggers }}
  triggers:
    {{- $authList := list }}
    {{- if .Values.autoscaling.keda.triggerAuthentications }}
      {{- if kindIs "slice" .Values.autoscaling.keda.triggerAuthentications }}
        {{- $authList = .Values.autoscaling.keda.triggerAuthentications }}
      {{- else if kindIs "map" .Values.autoscaling.keda.triggerAuthentications }}
        {{- range $k, $v := .Values.autoscaling.keda.triggerAuthentications }}
          {{- $item := merge (dict "name" $k) (deepCopy $v) }}
          {{- $authList = append $authList $item }}
        {{- end }}
      {{- end }}
    {{- else if .Values.autoscaling.keda.triggerAuthentication }}
      {{- $authList = list .Values.autoscaling.keda.triggerAuthentication }}
    {{- end }}
    {{- $authNameMap := dict }}
    {{- $defaultAuthName := include "tpl.resource.name" . }}
    {{- range $idx, $auth := $authList }}
      {{- $renderedName := "" }}
      {{- if $auth.name }}
        {{- if $auth.rawName }}
          {{- $renderedName = $auth.name }}
        {{- else }}
          {{- $renderedName = include "tpl.resource.name" (merge (dict "name" $auth.name) $) }}
        {{- end }}
        {{- $_ := set $authNameMap $auth.name $renderedName }}
      {{- else }}
        {{- $renderedName = include "tpl.resource.name" $ }}
        {{- $_ := set $authNameMap "default" $renderedName }}
      {{- end }}
      {{- if eq $idx 0 }}
        {{- $defaultAuthName = $renderedName }}
      {{- end }}
    {{- end }}
    {{- range $trigger := .Values.autoscaling.keda.triggers }}
    - type: {{ $trigger.type }}
      {{- if $trigger.name }}
      name: {{ $trigger.name }}
      {{- end }}
      {{- if $trigger.metricType }}
      metricType: {{ $trigger.metricType }}
      {{- end }}
      {{- with $trigger.metadata }}
      metadata:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if $trigger.authenticationRef }}
      authenticationRef:
        {{- if $trigger.authenticationRef.kind }}
        kind: {{ $trigger.authenticationRef.kind }}
        {{- end }}
        {{- $targetAuthName := $trigger.authenticationRef.name | default $defaultAuthName }}
        {{- if hasKey $authNameMap $targetAuthName }}
        name: {{ get $authNameMap $targetAuthName }}
        {{- else }}
        name: {{ $targetAuthName }}
        {{- end }}
      {{- end }}
      {{- with $trigger.useCachedMetrics }}
      useCachedMetrics: {{ . }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "tpl.keda" }}
{{- if and .Values.autoscaling.enabled (and .Values.autoscaling.keda .Values.autoscaling.keda.enabled) }}
  {{- $secrets := include "tpl.keda.secret" . | trim }}
  {{- if $secrets }}
{{ $secrets }}
  {{- end }}
  {{- $auths := include "tpl.keda.triggerauthentication" . | trim }}
  {{- if $auths }}
{{ $auths }}
  {{- end }}
---
{{ include "tpl.keda.scaledobject" . }}
{{- end }}
{{- end }}
