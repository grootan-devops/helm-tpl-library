{{- define "tpl.strToBool" -}}
  {{- $output := "" -}}
  {{- if or (eq . "true") (eq . "yes") (eq . "on") -}}
    {{- $output = "1" -}}
  {{- end -}}
  {{ $output }}
{{- end -}}
