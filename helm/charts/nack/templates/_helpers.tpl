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


{{/*
Fix image keys for chart versions <= 0.17.5
*/}}
{{- define "jsc.fixImage" -}}
{{- if kindIs "string" .image }}
{{- $_ := set . "image" (dict "repository" (split ":" .image)._0 "tag" ((split ":" .image)._1 | default "latest") "pullPolicy" "IfNotPresent") }}
{{- end }}
{{- if kindIs "string" .pullPolicy }}
{{- $_ := set .image "pullPolicy" .pullPolicy }}
{{- $_ := unset . "pullPolicy" }}
{{- end }}
{{- end }}

{{/*
Print the image
*/}}
{{- define "jsc.image" -}}
{{- $imageDict := .Values.jetstream.image }}
{{- $image := printf "%s:%s" $imageDict.repository (default .Chart.AppVersion $imageDict.tag) }}
{{- if $imageDict.registry }}
{{- $image = printf "%s/%s" $imageDict.registry $image }}
{{- end }}
{{- $image -}}
{{- end }}
