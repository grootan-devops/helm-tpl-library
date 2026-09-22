{{/*
Expand the name of the chart.
*/}}
{{- define "tpl.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tpl.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tpl.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "tpl.resource.siblingName" -}}
{{- printf "%s-%s" (.Release.Name | trunc (.Values.global.releaseNameLength | int)) .name }}
{{- end }}

{{/*
Create resorce name.
*/}}
{{- define "tpl.resource.name" -}}
{{- if .name -}}
{{- printf "%s-%s-%s" (.Release.Name | trunc (.Values.global.releaseNameLength | int)) (include "tpl.component.name" $) .name }}
{{- else -}}
{{- printf "%s-%s" (.Release.Name | trunc (.Values.global.releaseNameLength | int)) (include "tpl.component.name" $) }}
{{- end }}
{{- end }}

{{/*
Create resorce name for token.
*/}}
{{- define "tpl.resource.token.name" -}}
{{- if .name -}}
{{- printf "%s-%s-%s-token" (.Release.Name | trunc (.Values.global.releaseNameLength | int)) (include "tpl.component.name" $) .name }}
{{- else -}}
{{- printf "%s-%s-token" (.Release.Name | trunc (.Values.global.releaseNameLength | int)) (include "tpl.component.name" $) }}
{{- end }}
{{- end }}

{{- define "tpl.component.name" -}}
{{- if $.Values.subComponent }}
{{- printf "%s-%s" $.Values.component $.Values.subComponent }}
{{- else }}
{{- $.Values.component }}
{{- end }}
{{- end -}}

{{- define "tpl.container.name" -}}
{{- $explicit := ($._container).name | default "" -}}
{{- if $explicit -}}
{{- include "tpl.container.name.validate" (dict "out" (tpl $explicit $) "src" "explicit name") -}}
{{- else -}}
{{- $key := $._containerName | default "" -}}
{{- $isInit := eq ($._containerType | default "") "init" -}}
{{- if eq $key "main" -}}
{{- if $isInit -}}
{{- fail "tpl-library: the container key \"main\" is reserved for the single main workload container under `containers:`. Rename this init container to what it does (e.g. `db-migration`, `wait-for-db`)." -}}
{{- end -}}
{{- if eq ($.Values._workload | default "") "job" -}}
{{- fail "tpl-library: the container key \"main\" is reserved for the single main workload container under `containers:`. Rename this job container to what it does (e.g. `migrate`, `backup`)." -}}
{{- end -}}
{{- end -}}
{{- $prefix := "" -}}
{{- if $isInit -}}
{{- $prefix = "init-" -}}
{{- end -}}
{{- $budget := sub 63 (add (len $prefix) (len $key) 1) | int -}}
{{- if lt $budget 1 -}}
{{- fail (printf "tpl-library: container key %q is too long to build a name within the 63-character limit; shorten the key or set an explicit `name:`" $key) -}}
{{- end -}}
{{- $comp := include "tpl.component.name" $ | trunc $budget | trimSuffix "-" -}}
{{- $out := printf "%s%s-%s" $prefix $comp $key | trimSuffix "-" | trimPrefix "-" -}}
{{- include "tpl.container.name.validate" (dict "out" $out "src" (printf "container %q" $key)) -}}
{{- end -}}
{{- end -}}

{{- define "tpl.container.name.validate" -}}
{{- if not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" .out) -}}
{{- fail (printf "tpl-library: %s produced container name %q, which is not a valid DNS-1123 label (lowercase alphanumerics and '-', must start and end alphanumeric)" .src .out) -}}
{{- end -}}
{{- .out -}}
{{- end -}}
