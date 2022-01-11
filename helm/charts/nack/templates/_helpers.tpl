{{/*
Expand the name of the chart.
*/}}
{{- define "jsc.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Define the namespace where the content of the chart will be deployed.
*/}}
{{- define "jsc.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Define the serviceaccountname
*/}}
{{- define "jsc.serviceAccountName" -}}
{{- default "jetstream-controller" .Values.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
