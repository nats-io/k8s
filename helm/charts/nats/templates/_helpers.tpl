{{/*
Expand the name of the chart.
*/}}
{{- define "nats.name" -}}
{{- default .Release.Name -}}
{{- end -}}

{{/*
Return the proper NATS image name
*/}}
{{- define "nats.clusterAdvertise" -}}
{{- printf "$(POD_NAME).%s.$(POD_NAMESPACE).svc" (include "nats.name" . ) }}
{{- end }}

{{/*
Return the NATS cluster routes.
*/}}
{{- define "nats.clusterRoutes" -}}
{{- range $i, $e := until 3 -}}
{{- printf "nats://%s-%d.%s.%s.svc:6222," $.Release.Name $i $.Release.Name $.Release.Namespace -}}
{{- end -}}
{{- end }}
