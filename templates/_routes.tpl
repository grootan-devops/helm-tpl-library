{{/*
Port Resolver Helper: Converts named port or numeric string to integer port number for Gateway API HTTPRoute
*/}}
{{- define "tpl.routes.portResolver" -}}
  {{- $p := .port -}}
  {{- $res := 80 -}}
  {{- if or (kindIs "float64" $p) (kindIs "int" $p) (kindIs "int64" $p) -}}
    {{- $res = int $p -}}
  {{- else if kindIs "string" $p -}}
    {{- if regexMatch "^[0-9]+$" $p -}}
      {{- $res = int $p -}}
    {{- else if (and .Values.service (and .Values.service.default (and .Values.service.default.spec .Values.service.default.spec.ports))) -}}
      {{- range .Values.service.default.spec.ports -}}
        {{- if eq .name $p -}}
          {{- $res = .port -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- $res -}}
{{- end -}}

{{/*
Master Routes Template: Iterates over .Values.routes and renders Ingress and/or HTTPRoute
*/}}
{{- define "tpl.routes" -}}
{{- $routesMap := dict -}}
{{- if .Values.routes -}}
  {{- if hasKey .Values.routes "enabled" -}}
    {{- $routesMap = dict "default" .Values.routes -}}
  {{- else -}}
    {{- $routesMap = .Values.routes -}}
  {{- end -}}
{{- end -}}

{{- range $k, $route := $routesMap }}
{{- $enabled := true }}
{{- if hasKey $route "enabled" }}
  {{- $enabled = (include "tpl.strToBool" (tpl (toString $route.enabled) $)) }}
{{- end }}
{{- if $enabled }}

{{- /* Resource naming */}}
{{- $resourceName := include "tpl.resource.name" $ }}
{{- if ne $k "default" }}
  {{- $resourceName = include "tpl.resource.name" (merge (dict "name" $k) $) }}
{{- end }}

{{- /* Host resolution */}}
{{- $hosts := list }}
{{- if $route.hosts }}
  {{- range $route.hosts }}
    {{- $hosts = append $hosts (tpl . $) }}
  {{- end }}
{{- else if $route.host }}
  {{- $hosts = append $hosts (tpl $route.host $) }}
{{- else if (and $.Values.global (and $.Values.global.routes $.Values.global.routes.domain)) }}
  {{- $hosts = append $hosts (printf "%s.%s" $.Values.component $.Values.global.routes.domain) }}
{{- else if (and $.Values.global (and $.Values.global.ingress $.Values.global.ingress.domain)) }}
  {{- $hosts = append $hosts (printf "%s.%s" $.Values.component $.Values.global.ingress.domain) }}
{{- end }}

{{- /* Gateway configuration resolution */}}
{{- $gwObj := dict }}
{{- if and $.Values.global (and $.Values.global.routes $.Values.global.routes.gateway) }}
  {{- $gwObj = merge (deepCopy $.Values.global.routes.gateway) $gwObj }}
{{- end }}
{{- if $route.gateway }}
  {{- $gwObj = merge (deepCopy $route.gateway) $gwObj }}
{{- end }}
{{- $gwName := $gwObj.name | default $route.gatewayName | default $gwObj.class | default $route.class | default (and $.Values.global (and $.Values.global.routes (default $.Values.global.routes.gatewayName $.Values.global.routes.class))) | default "apisix-gateway" }}
{{- $gwNs := $gwObj.namespace | default $route.gatewayNamespace | default (and $.Values.global (and $.Values.global.routes (and $.Values.global.routes.gateway $.Values.global.routes.gateway.namespace))) | default (and $.Values.global (and $.Values.global.routes $.Values.global.routes.gatewayNamespace)) }}

{{- /* Normalized paths list */}}
{{- $paths := $route.paths | default (list (dict "path" "/" "pathType" "Prefix" "port" 80)) }}

{{- /* Render Ingress if enabled */}}
{{- $renderIngress := false }}
{{- if hasKey $route "ingress" }}
  {{- $renderIngress = (include "tpl.strToBool" (tpl (toString $route.ingress) $)) }}
{{- end }}
{{- if $renderIngress }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $resourceName }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    {{- if $route.annotations }}
      {{- tpl (toYaml $route.annotations) $ | nindent 4 }}
    {{- end }}
    {{- if $route.ingressAnnotations }}
      {{- tpl (toYaml $route.ingressAnnotations) $ | nindent 4 }}
    {{- end }}
spec:
  ingressClassName: {{ $route.ingressClass | default (and $.Values.global (and $.Values.global.routes $.Values.global.routes.ingressClass)) | default $gwObj.class | default $route.class | default (and $.Values.global (and $.Values.global.routes $.Values.global.routes.class)) | default (and $.Values.global (and $.Values.global.ingress $.Values.global.ingress.class)) }}
  {{- $tlsSecret := $route.tlsSecretName | default (and $.Values.global (and $.Values.global.routes $.Values.global.routes.tlsSecretName)) | default (and $.Values.global (and $.Values.global.ingress $.Values.global.ingress.tlsSecretName)) }}
  {{- if $tlsSecret }}
  tls:
    - secretName: {{ $tlsSecret }}
      hosts:
      {{- range $hosts }}
        - {{ . | quote }}
      {{- end }}
  {{- end }}
  rules:
  {{- range $h := $hosts }}
  - host: {{ $h | quote }}
    http:
      paths:
        {{- range $paths }}
        {{- $pItem := . }}
        {{- $pathList := list }}
        {{- if and .matches (not .path) }}
          {{- range .matches }}
            {{- if .path }}
              {{- $pathList = append $pathList (dict "path" (.path.value | default .path) "pathType" (.path.type | default "Prefix")) }}
            {{- end }}
          {{- end }}
        {{- else }}
          {{- $pathList = append $pathList (dict "path" (.path | default "/") "pathType" (.pathType | default "Prefix")) }}
        {{- end }}
        {{- range $pathList }}
        - path: {{ tpl .path $ }}
          pathType: {{ eq .pathType "PathPrefix" | ternary "Prefix" (.pathType | default "Prefix") }}
          {{- if $pItem.backend }}
          backend:
            service:
              name: {{ tpl $pItem.backend.service.name $ }}
              port:
                {{- if (and $pItem.backend.service.port.number (kindIs "float64" $pItem.backend.service.port.number )) }}
                number: {{ $pItem.backend.service.port.number | int }}
                {{- else if (and $pItem.backend.service.port.name (kindIs "string" $pItem.backend.service.port.name )) }}
                name: {{ $pItem.backend.service.port.name }}
                {{- else if $pItem.backend.service.port }}
                number: {{ $pItem.backend.service.port | int }}
                {{- else }}
                number: 80
                {{- end }}
          {{- else if $pItem.backendRefs }}
          {{- $firstRef := index $pItem.backendRefs 0 }}
          backend:
            service:
              name: {{ tpl ($firstRef.name | default (include "tpl.resource.name" $)) $ }}
              port:
                {{- if kindIs "string" $firstRef.port }}
                name: {{ $firstRef.port }}
                {{- else }}
                number: {{ $firstRef.port | default 80 | int }}
                {{- end }}
          {{- else }}
          backend:
            service:
              name: {{ include "tpl.resource.name" $ }}
              port:
                {{- if (and $pItem.port (or (kindIs "float64" $pItem.port) (kindIs "int" $pItem.port))) }}
                number: {{ $pItem.port | int }}
                {{- else if (and $pItem.port (kindIs "string" $pItem.port)) }}
                name: {{ $pItem.port }}
                {{- else }}
                number: 80
                {{- end }}
          {{- end }}
        {{- end }}
        {{- end }}
  {{- end }}
---
{{- end }}

{{- /* Render HTTPRoute if enabled */}}
{{- $renderHTTPRoute := false }}
{{- if hasKey $route "httpRoute" }}
  {{- $renderHTTPRoute = (include "tpl.strToBool" (tpl (toString $route.httpRoute) $)) }}
{{- end }}
{{- if $renderHTTPRoute }}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ $resourceName }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
  {{- $hasAnnotations := or $route.annotations (or $route.httpRouteAnnotations $route.plugins) }}
  {{- if $hasAnnotations }}
  annotations:
    {{- if $route.annotations }}
      {{- tpl (toYaml $route.annotations) $ | nindent 4 }}
    {{- end }}
    {{- if $route.httpRouteAnnotations }}
      {{- tpl (toYaml $route.httpRouteAnnotations) $ | nindent 4 }}
    {{- end }}
    {{- if $route.plugins }}
    k8s.apisix.apache.org/plugins: {{ toJson $route.plugins | quote }}
    {{- end }}
  {{- end }}
spec:
  parentRefs:
  {{- if $route.parentRefs }}
    {{- toYaml $route.parentRefs | nindent 4 }}
  {{- else }}
    - name: {{ $gwName }}
      {{- if $gwNs }}
      namespace: {{ $gwNs }}
      {{- end }}
      {{- if $route.sectionName }}
      sectionName: {{ $route.sectionName }}
      {{- end }}
      {{- if $route.gatewayPort }}
      port: {{ $route.gatewayPort | int }}
      {{- end }}
  {{- end }}
  {{- if $hosts }}
  hostnames:
  {{- range $hosts }}
    - {{ . | quote }}
  {{- end }}
  {{- end }}
  rules:
  {{- range $paths }}
  - {{- if .name }}
    name: {{ .name }}
    {{- end }}
    {{- if .matches }}
    matches:
      {{- range .matches }}
      - {{- if .path }}
        path:
          type: {{ eq (.path.type | default "PathPrefix") "Prefix" | ternary "PathPrefix" (.path.type | default "PathPrefix") }}
          value: {{ tpl (.path.value | default .path) $ | quote }}
        {{- end }}
        {{- if .method }}
        method: {{ .method }}
        {{- end }}
        {{- if .headers }}
        headers:
          {{- toYaml .headers | nindent 10 }}
        {{- end }}
        {{- if .queryParams }}
        queryParams:
          {{- toYaml .queryParams | nindent 10 }}
        {{- end }}
      {{- end }}
    {{- else }}
    matches:
    - path:
        type: {{ eq .pathType "Prefix" | ternary "PathPrefix" (.pathType | default "PathPrefix") }}
        value: {{ tpl (.path | default "/") $ | quote }}
      {{- if .method }}
      method: {{ .method }}
      {{- else if .methods }}
      method: {{ index .methods 0 }}
      {{- end }}
      {{- if .headers }}
      headers:
        {{- toYaml .headers | nindent 8 }}
      {{- end }}
      {{- if .queryParams }}
      queryParams:
        {{- toYaml .queryParams | nindent 8 }}
      {{- end }}
    {{- end }}
    {{- $filters := list }}
    {{- if .rewrite }}
      {{- $rewriteFilter := dict "type" "URLRewrite" "urlRewrite" dict }}
      {{- if .rewrite.hostname }}
        {{- $_ := set $rewriteFilter.urlRewrite "hostname" .rewrite.hostname }}
      {{- end }}
      {{- if .rewrite.path }}
        {{- $_ := set $rewriteFilter.urlRewrite "path" (dict "type" "ReplacePrefixMatch" "replacePrefixMatch" .rewrite.path) }}
      {{- else if .rewrite.replacePrefixMatch }}
        {{- $_ := set $rewriteFilter.urlRewrite "path" (dict "type" "ReplacePrefixMatch" "replacePrefixMatch" .rewrite.replacePrefixMatch) }}
      {{- else if .rewrite.replaceFullPath }}
        {{- $_ := set $rewriteFilter.urlRewrite "path" (dict "type" "ReplaceFullPath" "replaceFullPath" .rewrite.replaceFullPath) }}
      {{- end }}
      {{- $filters = append $filters $rewriteFilter }}
    {{- end }}
    {{- if .redirect }}
      {{- $redirectFilter := dict "type" "RequestRedirect" "requestRedirect" .redirect }}
      {{- $filters = append $filters $redirectFilter }}
    {{- end }}
    {{- if or .requestHeaders (and .headersFilter .headersFilter.request) }}
      {{- $reqH := .requestHeaders | default .headersFilter.request }}
      {{- $filters = append $filters (dict "type" "RequestHeaderModifier" "requestHeaderModifier" $reqH) }}
    {{- end }}
    {{- if or .responseHeaders (and .headersFilter .headersFilter.response) }}
      {{- $respH := .responseHeaders | default .headersFilter.response }}
      {{- $filters = append $filters (dict "type" "ResponseHeaderModifier" "responseHeaderModifier" $respH) }}
    {{- end }}
    {{- if .extensionRef }}
      {{- $extFilter := dict "type" "ExtensionRef" "extensionRef" .extensionRef }}
      {{- $filters = append $filters $extFilter }}
    {{- else if .pluginConfigName }}
      {{- $extFilter := dict "type" "ExtensionRef" "extensionRef" (dict "group" "apisix.apache.org" "kind" "ApisixPluginConfig" "name" .pluginConfigName) }}
      {{- $filters = append $filters $extFilter }}
    {{- end }}
    {{- if .filters }}
      {{- range .filters }}
        {{- $filters = append $filters . }}
      {{- end }}
    {{- end }}
    {{- if $filters }}
    filters:
      {{- toYaml $filters | nindent 6 }}
    {{- end }}
    backendRefs:
    {{- if .backendRefs }}
    {{- range .backendRefs }}
    - name: {{ tpl (.name | default (include "tpl.resource.name" $)) $ }}
      port: {{ include "tpl.routes.portResolver" (dict "port" .port "Values" $.Values) }}
      {{- if .weight }}
      weight: {{ .weight | int }}
      {{- end }}
      {{- if .filters }}
      filters:
        {{- toYaml .filters | nindent 8 }}
      {{- end }}
    {{- end }}
    {{- else if .backend }}
    - name: {{ tpl .backend.service.name $ }}
      {{- $bPort := .backend.service.port.number | default .backend.service.port.name | default .backend.service.port | default 80 }}
      port: {{ include "tpl.routes.portResolver" (dict "port" $bPort "Values" $.Values) }}
      weight: 100
    {{- else }}
    - name: {{ include "tpl.resource.name" $ }}
      port: {{ include "tpl.routes.portResolver" (dict "port" (.port | default 80) "Values" $.Values) }}
      weight: 100
    {{- end }}
    {{- if .timeouts }}
    timeouts:
      {{- toYaml .timeouts | nindent 6 }}
    {{- else if .timeout }}
    timeouts:
      request: {{ .timeout }}
    {{- end }}
    {{- if .retry }}
    retry:
      {{- toYaml .retry | nindent 6 }}
    {{- end }}
    {{- if .sessionPersistence }}
    sessionPersistence:
      {{- toYaml .sessionPersistence | nindent 6 }}
    {{- end }}
  {{- end }}
---
{{- end }}

{{- end }}
{{- end }}
{{- end -}}
