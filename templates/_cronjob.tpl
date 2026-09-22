{{- define "tpl.cronjob" }}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ include "tpl.resource.name" . }}
  labels: {{- include "tpl.labels" . | nindent 4 }}
spec: {{- include "tpl.cronjob.spec" . | nindent 2 }}
{{- end }}

{{- define "tpl.cronjob.spec" }}
schedule: {{ (._container).schedule | quote }}
concurrencyPolicy: {{ (._container).concurrencyPolicy }}
startingDeadlineSeconds: {{ (._container).startingDeadlineSeconds }}
successfulJobsHistoryLimit: {{ (._container).successfulJobsHistoryLimit }}
failedJobsHistoryLimit: {{ (._container).failedJobsHistoryLimit }}
suspend: {{ (._container).suspend }}
timeZone: {{ (._container).timeZone }}
ttlSecondsAfterFinished: {{ (._container).ttlSecondsAfterFinished }}
jobTemplate: 
  spec: {{- include "tpl.jobtemplate.spec" . | nindent 4 }}
    template:
      metadata:
        labels: {{- include "tpl.labels" . | nindent 10 }}
      spec: {{- include "tpl.pod.spec" (merge (dict "_container" .Values) .) | nindent 8 }}
{{- end }}
