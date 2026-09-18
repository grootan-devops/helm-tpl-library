{{/*
PersistentVolumeClaims.

Optional entrypoint, like tpl.job and tpl.cronjob: tpl.deployment does NOT call it.
tpl.pod.spec renders a pod volume with persistentVolumeClaim.claimName for every enabled
entry under mounts.pvc, but it never creates the claim itself -- a mount with nothing
backing it leaves the pod Pending while helm reports success. Consumers that need the
chart to own the claim add this alongside tpl.deployment:

  {{- include "tpl.pvc" . }}

Each entry under .Values.persistence renders one claim named <resource name>-<key>, which
is the same name mounts.pvc defaults to, so the two line up without repeating the string.
An entry with existingClaim set renders nothing: the operator is reusing a claim this
chart must not own or delete.
*/}}
{{- define "tpl.pvc" }}
{{- range $key, $claim := .Values.persistence }}
{{- if and $claim.enabled (not $claim.existingClaim) }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ printf "%s-%s" (include "tpl.resource.name" $) $key }}
  labels: {{- include "tpl.labels" $ | nindent 4 }}
  {{- with $claim.annotations }}
  annotations: {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  accessModes: {{- toYaml ($claim.accessModes | default (list "ReadWriteOnce")) | nindent 4 }}
  volumeMode: {{ $claim.volumeMode | default "Filesystem" }}
  resources:
    requests:
      storage: {{ required (printf "persistence.%s.size is required when enabled" $key) $claim.size }}
  {{- if $claim.storageClass }}
  storageClassName: {{ $claim.storageClass | quote }}
  {{- end }}
  {{- with $claim.selector }}
  selector: {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
