{{/*
Expand the name of the chart.
*/}}
{{- define "stan.name" -}}
{{- default .Release.Name -}}
{{- end -}}

{{/*
Return the list of peers in a NATS Streaming cluster.
*/}}
{{- define "stan.clusterPeers" -}}
{{- range $i, $e := until 3 -}}
{{- printf "'%s-%d'," $.Release.Name $i -}}
{{- end -}}
{{- end }}
