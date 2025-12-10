{{/*
Generate the name of the credentials secret
*/}}
{{- define "nextcloud.secretName" -}}
{{- if .Values.existingSecret -}}
{{- .Values.existingSecret -}}
{{- else -}}
{{- printf "%s-credentials" .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
Generate service names based on release name
*/}}
{{- define "nextcloud.postgresqlHost" -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}

{{- define "nextcloud.redisHost" -}}
{{- printf "%s-redis" .Release.Name -}}
{{- end -}}
