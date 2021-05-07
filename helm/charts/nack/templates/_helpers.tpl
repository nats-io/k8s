{{/*
Expand the name of the chart.
*/}}
{{- define "jsc.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Define the serviceaccountname
*/}}
{{- define "jsc.serviceAccountName" -}}
{{- default "jetstream-controller" .Values.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
