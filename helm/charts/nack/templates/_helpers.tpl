{{/*
Expand the name of the chart.
*/}}
{{- define "jsc.name" -}}
{{- if .Values.useLegacyNames }}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "jsc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels - returns modern or legacy labels based on useLegacyNames flag.
*/}}
{{- define "jsc.labels" -}}
{{- if .Values.useLegacyNames -}}
app: {{ include "jsc.name" . }}
chart: {{ include "jsc.chart" . }}
{{- else -}}
helm.sh/chart: {{ include "jsc.chart" . }}
{{ include "jsc.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- with ((.Values.global).labels) }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels - returns modern or legacy labels based on useLegacyNames flag.
*/}}
{{- define "jsc.selectorLabels" -}}
{{- if .Values.useLegacyNames -}}
app: {{ include "jsc.name" . }}
{{- else -}}
app.kubernetes.io/name: {{ include "jsc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
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
