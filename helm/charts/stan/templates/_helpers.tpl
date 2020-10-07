{{/*
Expand the name of the chart.
*/}}
{{- define "stan.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the list of peers in a NATS Streaming cluster.
*/}}
{{- define "stan.clusterPeers" -}}
{{- range $i, $e := until (int $.Values.stan.replicas) -}}
{{- printf "'%s-%d'," (include "stan.name" $) $i -}}
{{- end -}}
{{- end }}

{{- define "stan.replicaCount" -}}
{{- $replicas := (int $.Values.stan.replicas) -}}
{{- if and $.Values.store.cluster.enabled (lt $replicas 3) -}}
{{- $replicas = "" -}}
{{- end -}}
{{ print $replicas }}
{{- end -}}

{{/*
Define the serviceaccountname
*/}}
{{- define "stan.serviceAccountName" -}}
{{- default "nats-streaming" .Values.serviceAccountName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the proper NATS image name
*/}}
{{- define "nats.clusterAdvertise" -}}
{{- printf "$(POD_NAME).%s.$(POD_NAMESPACE).svc" (include "stan.name" . ) }}
{{- end }}

{{/*
Return the NATS cluster routes.
*/}}
{{- define "nats.clusterRoutes" -}}
{{- $name := default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- range $i, $e := until (.Values.stan.replicas | int) -}}
{{- printf "nats://%s-%d.%s.%s.svc:6222," $name $i $name $.Release.Namespace -}}
{{- end -}}
{{- end }}


