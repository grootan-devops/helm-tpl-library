{{- define "tpl.pod.spec" }}
{{- if .Values.serviceAccount.create }}
serviceAccountName: {{ include "tpl.resource.name" . }}
{{- else }}
automountServiceAccountToken: false
{{- end }}
securityContext: {{- .Values.pod.securityContext | toYaml | nindent 2 }}
{{- if .Values.restartPolicy }}
restartPolicy: {{ .Values.restartPolicy }}
{{- end }}
{{- if .Values.scheduling.topologySpreadConstraints }}
topologySpreadConstraints: {{- .Values.scheduling.topologySpreadConstraints | toYaml | nindent 2 }}
{{- end }}
{{- if .Values.scheduling.tolerations }}
tolerations: {{- .Values.scheduling.tolerations | toYaml | nindent 2 }}
{{- end }}
{{- if .Values.scheduling.nodeSelector }}
nodeSelector: {{- .Values.scheduling.nodeSelector | toYaml | nindent 2 }}
{{- end }}
affinity: {{- .Values.scheduling.affinity | toYaml | nindent 2 }}
{{- if .Values.initContainers }}
initContainers:
{{- range $key := keys .Values.initContainers | sortAlpha }}
  {{- $container := get $.Values.initContainers $key }}
  {{- include "tpl.container" (dict "Values" $.Values "Release" $.Release "Chart" $.Chart "Template" $.Template "Capabilities" $.Capabilities "_container" $container "_containerName" $key "_containerType" "init" "name" $.name) | nindent 2 }}
{{- end }}
{{- end }}
{{- if .Values.hostAliases }}
hostAliases: {{- .Values.hostAliases | toYaml | nindent 2 }}
{{- end }}
{{- if .Values.global.image.pullSecrets }}
imagePullSecrets:
  {{- range .Values.global.image.pullSecrets }}
  - name: {{ . }}
  {{- end }}
{{- end }}
containers:
{{- range $key := keys .Values.containers | sortAlpha }}
  {{- $container := get $.Values.containers $key }}
  {{- include "tpl.container" (dict "Values" $.Values "Release" $.Release "Chart" $.Chart "Template" $.Template "Capabilities" $.Capabilities "_container" $container "_containerName" $key "_containerType" "main" "name" $.name) | nindent 2 }}
{{- end }}

{{- $containers := list }}
{{- range $key := keys .Values.containers | sortAlpha }}
  {{- $container := get $.Values.containers $key }}
  {{- $name := tpl ($container.name | default $key | default (include "tpl.component.name" $)) $ }}
  {{- $containers = append $containers (dict "name" $name "type" "main" "key" $key) }}
{{- end }}
{{- range $key := keys .Values.initContainers | sortAlpha }}
  {{- $container := get $.Values.initContainers $key }}
  {{- $name := tpl ($container.name | default $key | default (include "tpl.component.name" $)) $ }}
  {{- $containers = append $containers (dict "name" $name "type" "init" "key" $key) }}
{{- end }}

{{- $hasVolumes := false }}
{{- range $type := list "configmap" "secret" "emptyDir" "pvc" }}
  {{- range $key, $val := (index $.Values.mounts $type) }}
      {{- if $val }}
    {{- $rawMountTo := $val.mountTo | default "both" }}
    {{- $mountList := list }}
    {{- if kindIs "slice" $rawMountTo }}
      {{- range $m := $rawMountTo }}
        {{- $mountList = append $mountList (tpl $m $) }}
      {{- end }}
    {{- else }}
      {{- $mountList = list (tpl $rawMountTo $) }}
    {{- end }}
      {{- $enabled := include "tpl.strToBool" (tpl ($val.enabled | toString | default "true") $) }}
      {{- range $c := $containers }}
        {{- if and $enabled (or (has "both" $mountList) (has $c.type $mountList) (has $c.name $mountList) (has $c.key $mountList)) }}
          {{- $hasVolumes = true }}
        {{- end }}
      {{- end }}
      {{- end }}
  {{- end }}
{{- end }}

{{- if $hasVolumes }}
volumes:
  {{- range $key, $val := .Values.mounts.secret }}
    {{- if $val }}
    {{- $rawMountTo := $val.mountTo | default "both" }}
    {{- $mountList := list }}
    {{- if kindIs "slice" $rawMountTo }}
      {{- range $m := $rawMountTo }}
        {{- $mountList = append $mountList (tpl $m $) }}
      {{- end }}
    {{- else }}
      {{- $mountList = list (tpl $rawMountTo $) }}
    {{- end }}
    {{- $enabled := include "tpl.strToBool" (tpl ($val.enabled | toString | default "true") $) }}
    {{- range $c := $containers }}
      {{- if and $enabled (or (has "both" $mountList) (has $c.type $mountList) (has $c.name $mountList) (has $c.key $mountList)) }}
      {{- $volName := printf "%s-%s-%s" (include "tpl.resource.name" $) $c.key $key }}
      {{- if and $.name (eq $.name $c.key) }}
        {{- $volName = printf "%s-%s" (include "tpl.resource.name" $) $key }}
      {{- end }}
  - name: {{ $volName }}
    secret:
      secretName: {{ $volName }}
      {{- if and $val.params $val.params.defaultMode }}
      defaultMode: {{ $val.params.defaultMode }}
      {{- end }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}

  {{- range $key, $val := .Values.mounts.configmap }}
    {{- if $val }}
    {{- $rawMountTo := $val.mountTo | default "both" }}
    {{- $mountList := list }}
    {{- if kindIs "slice" $rawMountTo }}
      {{- range $m := $rawMountTo }}
        {{- $mountList = append $mountList (tpl $m $) }}
      {{- end }}
    {{- else }}
      {{- $mountList = list (tpl $rawMountTo $) }}
    {{- end }}
    {{- $enabled := include "tpl.strToBool" (tpl ($val.enabled | toString | default "true") $) }}
    {{- range $c := $containers }}
      {{- if and $enabled (or (has "both" $mountList) (has $c.type $mountList) (has $c.name $mountList) (has $c.key $mountList)) }}
      {{- $volName := printf "%s-%s-%s" (include "tpl.resource.name" $) $c.key $key }}
      {{- if and $.name (eq $.name $c.key) }}
        {{- $volName = printf "%s-%s" (include "tpl.resource.name" $) $key }}
      {{- end }}
  - name: {{ $volName }}
    configMap:
      name: {{ $volName }}
      {{- if and $val.params $val.params.defaultMode }}
      defaultMode: {{ $val.params.defaultMode }}
      {{- end }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}

  {{- range $key, $val := .Values.mounts.emptyDir }}
    {{- if $val }}
    {{- $rawMountTo := $val.mountTo | default "both" }}
    {{- $mountList := list }}
    {{- if kindIs "slice" $rawMountTo }}
      {{- range $m := $rawMountTo }}
        {{- $mountList = append $mountList (tpl $m $) }}
      {{- end }}
    {{- else }}
      {{- $mountList = list (tpl $rawMountTo $) }}
    {{- end }}
    {{- $enabled := include "tpl.strToBool" (tpl ($val.enabled | toString | default "true") $) }}
    {{- $isUsed := false }}
    {{- range $c := $containers }}
      {{- if or (has "both" $mountList) (has $c.type $mountList) (has $c.name $mountList) (has $c.key $mountList) }}
        {{- $isUsed = true }}
      {{- end }}
    {{- end }}
    {{- if and $enabled $isUsed }}
  - name: {{ include "tpl.resource.name" $ }}-{{ $key }}
    emptyDir:
      {{- if and $val.params $val.params.medium }}
      medium: {{ $val.params.medium }}
      {{- end }}
      {{- if and $val.params $val.params.sizeLimit }}
      sizeLimit: {{ $val.params.sizeLimit }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}

  {{- range $key, $val := .Values.mounts.pvc }}
    {{- if $val }}
    {{- $rawMountTo := $val.mountTo | default "both" }}
    {{- $mountList := list }}
    {{- if kindIs "slice" $rawMountTo }}
      {{- range $m := $rawMountTo }}
        {{- $mountList = append $mountList (tpl $m $) }}
      {{- end }}
    {{- else }}
      {{- $mountList = list (tpl $rawMountTo $) }}
    {{- end }}
    {{- $enabled := include "tpl.strToBool" (tpl ($val.enabled | toString | default "true") $) }}
    {{- $isUsed := false }}
    {{- range $c := $containers }}
      {{- if or (has "both" $mountList) (has $c.type $mountList) (has $c.name $mountList) (has $c.key $mountList) }}
        {{- $isUsed = true }}
      {{- end }}
    {{- end }}
    {{- if and $enabled $isUsed }}
  - name: {{ include "tpl.resource.name" $ }}-{{ $key }}
    persistentVolumeClaim:
      {{- /* tpl errors on nil, so it cannot be evaluated before defaulting -- the
             documented default only works if claimName is checked first. Unset means
             the claim tpl.pvc creates for the same key. */}}
      claimName: {{ if $val.claimName }}{{ tpl $val.claimName $ }}{{ else }}{{ printf "%s-%s" (include "tpl.resource.name" $) $key }}{{ end }}
    {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}