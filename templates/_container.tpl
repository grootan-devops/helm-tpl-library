{{- define "tpl.container" }}
{{- $containerName := include "tpl.container.name" $ }}

{{- $envSuffix := printf "%s-env" ._containerName }}
{{- if .name }}
  {{- if eq .name ._containerName }}
    {{- $envSuffix = printf "%s-env" .name }}
  {{- else }}
    {{- $envSuffix = printf "%s-%s-env" .name ._containerName }}
  {{- end }}
{{- end }}

- name: {{ $containerName }}
  {{- if (._container).command }}
  command: {{- tpl (toYaml (._container).command) $ | nindent 4 }}
  {{- end }}
  {{- if (._container).args }}
  args: {{- tpl (toYaml (._container).args) $ | nindent 4 }}
  {{- end }}
  image: {{ printf "%s/%s:%s" ((._container).image.registry | default .Values.global.image.registry ) (include "tpl.container.image.repository" $) ((._container).image.tag | default .Chart.AppVersion) | quote }}
  imagePullPolicy: {{ .Values.global.image.pullPolicy }}
  {{- if (._container).env }}
  env: {{- (._container).env | toYaml | nindent 4 }}
  {{- end }}
  {{- if (._container).resizePolicy }}
  resizePolicy: {{ (._container).resizePolicy | toYaml | nindent 4 }}
  {{- end }}

  {{- if or (._container).extraConfigmapMounts (._container).extraSecretMounts (._container).configmapEnvs (._container).secretEnvs }}
  envFrom:
    {{- if or (._container).secretEnvs (._container).additionalSecretEnvs }}
    - secretRef:
        name: {{ include "tpl.resource.name" (dict "name" $envSuffix "Release" $.Release "Values" $.Values) }}
    {{- end }}
    {{- if or (._container).configmapEnvs (._container).additionalConfigmapEnvs }}
    - configMapRef:
        name: {{ include "tpl.resource.name" (dict "name" $envSuffix "Release" $.Release "Values" $.Values) }}
    {{- end }}
    {{- if (._container).extraConfigmapMounts }}
    {{- range (._container).extraConfigmapMounts }}
    - configMapRef:
        name: {{ . }}
    {{- end }}
    {{- end }}
    {{- if (._container).extraSecretMounts }}
    {{- range (._container).extraSecretMounts }}
    - secretRef:
        name: {{ . }}
    {{- end }}
    {{- end }}
  {{- end }}

  {{- $services := (._container).service }}
  {{- if and (not $services) $.Values.service (eq ._containerType "main") }}
    {{- $services = $.Values.service }}
  {{- end }}

  {{- if $services }}
  ports:
  {{- $visitedPorts := dict -}}
  {{- range $services }}
  {{- if .spec }}
  {{- range .spec.ports }}
  {{- $portName := .name }}
  {{- $visited := index $visitedPorts $portName }}
  {{- if not $visited }}
    - containerPort: {{ .targetPort | default .port }}
      name: {{ $portName }}
      protocol: {{ .protocol | default "TCP" }}
    {{- $_ := set $visitedPorts $portName true }}
  {{- end }}
  {{- end }}
  {{- end }}
  {{- end }}
  {{- end }}

  {{- if (._container).resources }}
  resources: {{- (._container).resources | toYaml | nindent 4 }}
  {{- end }}
  {{- if (._container).securityContext }}
  securityContext: {{- (._container).securityContext | toYaml | nindent 4 }}
  {{- end }}
  
  {{- if and (._container).probes (._container).probes.enabled }}
  {{- if (._container).probes.liveness }}
  livenessProbe: {{- (._container).probes.liveness | toYaml | nindent 4 }}
  {{- end }}
  {{- if (._container).probes.readiness }}
  readinessProbe: {{- (._container).probes.readiness | toYaml | nindent 4 }}
  {{- end }}
  {{- if (._container).probes.startup }}
  startupProbe: {{- (._container).probes.startup | toYaml | nindent 4 }}
  {{- end }}
  {{- end }}

  {{- $hasMounts := false }}
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
       {{- if include "tpl.strToBool" (tpl ($val.enabled | toString | default "true") $) }}
        {{- if or (has "both" $mountList) (has $._containerType $mountList) (has $containerName $mountList) (has $._containerName $mountList) }}
          {{- $hasMounts = true }}
        {{- end }}
      {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if $hasMounts }}
  volumeMounts:
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
    {{- if include "tpl.strToBool" (tpl ($val.enabled | toString | default "true") $) }}
      {{- if or (has "both" $mountList) (has $._containerType $mountList) (has $containerName $mountList) (has $._containerName $mountList) }}
      {{- $volName := printf "%s-%s-%s" (include "tpl.resource.name" $) $._containerName $key }}
      {{- if and $.name (eq $.name $._containerName) }}
        {{- $volName = printf "%s-%s" (include "tpl.resource.name" $) $key }}
      {{- end }}
    - name: {{ $volName }}
      mountPath: {{ $val.path }}
      {{- if and $val.params $val.params.readOnly }}
      readOnly: {{ $val.params.readOnly }}
      {{- end }}
      {{- if $val.subPath }}
      subPath: {{ $val.subPath }}
      {{- end }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}
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
    {{- if include "tpl.strToBool" (tpl ($val.enabled | toString | default "true") $) }}
      {{- if or (has "both" $mountList) (has $._containerType $mountList) (has $containerName $mountList) (has $._containerName $mountList) }}
      {{- $volName := printf "%s-%s-%s" (include "tpl.resource.name" $) $._containerName $key }}
      {{- if and $.name (eq $.name $._containerName) }}
        {{- $volName = printf "%s-%s" (include "tpl.resource.name" $) $key }}
      {{- end }}
    - name: {{ $volName }}
      mountPath: {{ $val.path }}
      {{- if and $val.params $val.params.readOnly }}
      readOnly: {{ $val.params.readOnly }}
      {{- end }}
      {{- if $val.subPath }}
      subPath: {{ $val.subPath }}
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
    {{- if include "tpl.strToBool" (tpl ($val.enabled | toString | default "true") $) }}
      {{- if or (has "both" $mountList) (has $._containerType $mountList) (has $containerName $mountList) (has $._containerName $mountList) }}
    - name: {{ include "tpl.resource.name" $ }}-{{ $key }}
      mountPath: {{ $val.path }}
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
    {{- if include "tpl.strToBool" (tpl ($val.enabled | toString | default "true") $) }}
      {{- if or (has "both" $mountList) (has $._containerType $mountList) (has $containerName $mountList) (has $._containerName $mountList) }}
    - name: {{ include "tpl.resource.name" $ }}-{{ $key }}
      mountPath: {{ tpl $val.path $ }}
      {{- end }}
    {{- end }}
    {{- end }}
  {{- end }}
  {{- end }}
{{- end }}
