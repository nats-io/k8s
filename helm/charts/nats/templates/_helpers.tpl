{{/*
Expand the name of the chart.
*/}}
{{- define "nats.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
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
{{- $name := default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- range $i, $e := until (.Values.cluster.replicas | int) -}}
{{- printf "nats://%s-%d.%s.%s.svc:6222," $name $i $name $.Release.Namespace -}}
{{- end -}}
{{- end }}
