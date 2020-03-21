{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Release.Name -}}
{{- end -}}
