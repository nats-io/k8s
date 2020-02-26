{{/*
Expand the name of the chart.
*/}}
{{- define "stan.name" -}}
{{- default .Release.Name -}}
{{- end -}}
