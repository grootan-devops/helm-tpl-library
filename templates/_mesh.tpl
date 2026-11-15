{{/*
PeerAuthentication Template: Renders security.istio.io/v1 PeerAuthentication
*/}}
{{- define "tpl.mesh.istio.peerauthentication" }}
{{- if and .Values.serviceMesh .Values.serviceMesh.enabled }}
{{- $istio := .Values.serviceMesh.istio | default .Values.serviceMesh }}
{{- $pa := $istio.peerAuthentication }}
{{- if $pa }}
{{- $paEnabled := true }}
{{- if hasKey $pa "enabled" }}
  {{- $paEnabled = (include "tpl.strToBool" (tpl (toString $pa.enabled) $)) }}
{{- end }}
{{- if $paEnabled }}
{{- $name := include "tpl.resource.name" $ }}
{{- if $pa.name }}
  {{- $name = include "tpl.resource.name" (merge (dict "name" $pa.name) $) }}
{{- end }}
---
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: {{ $name }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
  {{- with $pa.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if $pa.selector }}
  selector:
    {{- toYaml $pa.selector | nindent 4 }}
  {{- else }}
  selector:
    matchLabels: {{- include "tpl.selectorLabels" $ | nindent 6 }}
  {{- end }}
  {{- with $pa.mtls }}
  mtls:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $pa.portLevelMtls }}
  portLevelMtls:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
RequestAuthentication Template: Renders security.istio.io/v1 RequestAuthentication list
*/}}
{{- define "tpl.mesh.istio.requestauthentication" }}
{{- if and .Values.serviceMesh .Values.serviceMesh.enabled }}
{{- $istio := .Values.serviceMesh.istio | default .Values.serviceMesh }}
{{- range $item := $istio.requestAuthentications }}
{{- $name := include "tpl.resource.name" $ }}
{{- if $item.name }}
  {{- $name = include "tpl.resource.name" (merge (dict "name" $item.name) $) }}
{{- end }}
---
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: {{ $name }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
  {{- with $item.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if $item.targetRefs }}
  targetRefs:
    {{- toYaml $item.targetRefs | nindent 4 }}
  {{- else if $item.selector }}
  selector:
    {{- toYaml $item.selector | nindent 4 }}
  {{- else }}
  targetRefs:
    - group: ""
      kind: Service
      name: {{ include "tpl.resource.name" $ }}
  {{- end }}
  {{- with $item.jwtRules }}
  jwtRules:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
AuthorizationPolicy Template: Renders security.istio.io/v1 AuthorizationPolicy list
*/}}
{{- define "tpl.mesh.istio.authorizationpolicy" }}
{{- if and .Values.serviceMesh .Values.serviceMesh.enabled }}
{{- $istio := .Values.serviceMesh.istio | default .Values.serviceMesh }}
{{- range $item := $istio.authorizationPolicies }}
{{- $name := include "tpl.resource.name" $ }}
{{- if $item.name }}
  {{- $name = include "tpl.resource.name" (merge (dict "name" $item.name) $) }}
{{- end }}
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: {{ $name }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
  {{- with $item.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if $item.action }}
  action: {{ $item.action }}
  {{- end }}
  {{- if $item.targetRefs }}
  targetRefs:
    {{- toYaml $item.targetRefs | nindent 4 }}
  {{- else if $item.selector }}
  selector:
    {{- toYaml $item.selector | nindent 4 }}
  {{- else }}
  selector:
    matchLabels: {{- include "tpl.selectorLabels" $ | nindent 6 }}
  {{- end }}
  {{- with $item.rules }}
  rules:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
DestinationRule Template: Renders networking.istio.io/v1 DestinationRule list
*/}}
{{- define "tpl.mesh.istio.destinationrule" }}
{{- if and .Values.serviceMesh .Values.serviceMesh.enabled }}
{{- $istio := .Values.serviceMesh.istio | default .Values.serviceMesh }}
{{- range $item := $istio.destinationRules }}
{{- $name := include "tpl.resource.name" $ }}
{{- if $item.name }}
  {{- $name = include "tpl.resource.name" (merge (dict "name" $item.name) $) }}
{{- end }}
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: {{ $name }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
  {{- with $item.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  host: {{ $item.host | default (include "tpl.resource.name" $) }}
  {{- with $item.trafficPolicy }}
  trafficPolicy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $item.subsets }}
  subsets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $item.workloadSelector }}
  workloadSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $item.exportTo }}
  exportTo:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Combined ExternalServices Template: Renders ServiceEntry + BackendTLSPolicy + DestinationRule
for external 3rd-party services with automatic HTTPS TLS origination and System CA validation.
*/}}
{{- define "tpl.mesh.istio.externalservices" }}
{{- if and .Values.serviceMesh .Values.serviceMesh.enabled }}
{{- $istio := .Values.serviceMesh.istio | default .Values.serviceMesh }}
{{- if $istio.externalServices }}
{{- range $idx, $item := $istio.externalServices }}
  {{- $hostList := list }}
  {{- if $item.hosts }}
    {{- if kindIs "slice" $item.hosts }}
      {{- $hostList = $item.hosts }}
    {{- else }}
      {{- $hostList = list $item.hosts }}
    {{- end }}
  {{- else if $item.host }}
    {{- if kindIs "slice" $item.host }}
      {{- $hostList = $item.host }}
    {{- else }}
      {{- $hostList = list $item.host }}
    {{- end }}
  {{- end }}
  {{- if $hostList }}
    {{- $firstHostClean := ($hostList | first | toString | replace "." "-" | replace ":" "-" | lower) }}
    {{- $seName := include "tpl.resource.name" (merge (dict "name" ($item.name | default (printf "ext-%s" $firstHostClean))) $) }}
---
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: {{ $seName }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
  {{- with $item.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  hosts:
    {{- range $h := $hostList }}
    - {{ $h | quote }}
    {{- end }}
  location: {{ $item.location | default "MESH_EXTERNAL" }}
  resolution: {{ $item.resolution | default "DNS" }}
  ports:
    {{- if $item.ports }}
      {{- toYaml $item.ports | nindent 4 }}
    {{- else }}
    - number: {{ $item.number | default ($item.port | default 80) | int }}
      name: {{ $item.portName | default "http" }}
      protocol: {{ $item.protocol | default "HTTP" }}
      targetPort: {{ $item.targetPort | default 443 | int }}
    {{- end }}
  {{- with $item.endpoints }}
  endpoints:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $item.exportTo }}
  exportTo:
    {{- toYaml . | nindent 4 }}
  {{- end }}
    {{- $enableTLS := true }}
    {{- if hasKey $item "tls" }}
      {{- $enableTLS = (include "tpl.strToBool" (tpl (toString $item.tls) $)) }}
    {{- end }}
    {{- if $enableTLS }}
      {{- range $h := $hostList }}
        {{- $hostClean := ($h | toString | replace "." "-" | replace ":" "-" | lower) }}
        {{- $btpName := include "tpl.resource.name" (merge (dict "name" (printf "btp-%s" $hostClean)) $) }}
        {{- $drName := include "tpl.resource.name" (merge (dict "name" (printf "dr-ext-%s" $hostClean)) $) }}
---
apiVersion: gateway.networking.k8s.io/v1alpha3
kind: BackendTLSPolicy
metadata:
  name: {{ $btpName }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
spec:
  targetRefs:
    - group: networking.istio.io
      kind: ServiceEntry
      name: {{ $seName }}
  validation:
    hostname: {{ $h }}
    wellKnownCACertificates: {{ $item.wellKnownCACertificates | default "System" }}
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: {{ $drName }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
spec:
  host: {{ $h }}
  trafficPolicy:
    tls:
      mode: {{ $item.mode | default ($item.tlsMode | default "SIMPLE") }}
      sni: {{ $item.sni | default $h }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Istio Waypoint Labels: Service label generator for Istio Ambient (hardcoded to Service)
*/}}
{{- define "tpl.mesh.istio.waypoint.podLabels" }}
{{- end }}

{{- define "tpl.mesh.istio.waypoint.serviceLabels" }}
{{- if and $.Values.serviceMesh $.Values.serviceMesh.enabled }}
  {{- $istio := $.Values.serviceMesh.istio | default $.Values.serviceMesh }}
  {{- if and $istio.waypoint $istio.waypoint.enabled }}
istio.io/use-waypoint: {{ $istio.waypoint.name | quote }}
istio.io/use-waypoint-namespace: {{ $istio.waypoint.namespace | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Istio Orchestrator Template: Coordinates all enabled Istio resources
*/}}
{{- define "tpl.mesh.istio" }}
  {{- $pa := include "tpl.mesh.istio.peerauthentication" . | trim }}
  {{- if $pa }}
{{ $pa }}
  {{- end }}
  {{- $ra := include "tpl.mesh.istio.requestauthentication" . | trim }}
  {{- if $ra }}
{{ $ra }}
  {{- end }}
  {{- $ap := include "tpl.mesh.istio.authorizationpolicy" . | trim }}
  {{- if $ap }}
{{ $ap }}
  {{- end }}
  {{- $dr := include "tpl.mesh.istio.destinationrule" . | trim }}
  {{- if $dr }}
{{ $dr }}
  {{- end }}
  {{- $ext := include "tpl.mesh.istio.externalservices" . | trim }}
  {{- if $ext }}
{{ $ext }}
  {{- end }}
{{- end }}

{{/*
Master Mesh Template: Coordinates all enabled Service Mesh resources (provider-agnostic entrypoint)
*/}}
{{- define "tpl.mesh" }}
{{- if and .Values.serviceMesh .Values.serviceMesh.enabled }}
  {{- $type := .Values.serviceMesh.type | default "istio" }}
  {{- if eq $type "istio" }}
{{ include "tpl.mesh.istio" . }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Generic ServiceMesh Waypoint Helpers: Non-provider specific delegation
*/}}
{{- define "tpl.mesh.waypoint.podLabels" }}
{{- if and .Values.serviceMesh .Values.serviceMesh.enabled }}
  {{- $type := .Values.serviceMesh.type | default "istio" }}
  {{- if eq $type "istio" }}
{{- include "tpl.mesh.istio.waypoint.podLabels" . }}
  {{- end }}
{{- end }}
{{- end }}

{{- define "tpl.mesh.waypoint.serviceLabels" }}
{{- if and $.Values.serviceMesh $.Values.serviceMesh.enabled }}
  {{- $type := $.Values.serviceMesh.type | default "istio" }}
  {{- if eq $type "istio" }}
{{- include "tpl.mesh.istio.waypoint.serviceLabels" $ }}
  {{- end }}
{{- end }}
{{- end }}

{{/* Backward compatibility aliases */}}
{{- define "tpl.mesh.peerauthentication" }}{{ include "tpl.mesh.istio.peerauthentication" . }}{{ end }}
{{- define "tpl.mesh.requestauthentication" }}{{ include "tpl.mesh.istio.requestauthentication" . }}{{ end }}
{{- define "tpl.mesh.authorizationpolicy" }}{{ include "tpl.mesh.istio.authorizationpolicy" . }}{{ end }}
{{- define "tpl.mesh.destinationrule" }}{{ include "tpl.mesh.istio.destinationrule" . }}{{ end }}
{{- define "tpl.mesh.externalservices" }}{{ include "tpl.mesh.istio.externalservices" . }}{{ end }}
