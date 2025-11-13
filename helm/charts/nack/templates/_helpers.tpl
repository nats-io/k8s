{{/*
Expand the name of the chart.
*/}}
{{- define "jsc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "jsc.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "jsc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "jsc.labels" -}}
helm.sh/chart: {{ include "jsc.chart" . }}
{{ include "jsc.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "jsc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "jsc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

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
