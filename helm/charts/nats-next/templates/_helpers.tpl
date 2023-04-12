{{/*
Expand the name of the chart.
*/}}
{{- define "nats.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nats.fullname" -}}
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
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nats.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
NATS Common labels
*/}}
{{- define "nats.labels" -}}
helm.sh/chart: {{ include "nats.chart" . }}
{{ include "nats.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
NATS Selector labels
*/}}
{{- define "nats.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nats.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: nats
{{- end }}

{{/*
NATS Box labels
*/}}
{{- define "natsBox.labels" -}}
helm.sh/chart: {{ include "nats.chart" . }}
{{ include "natsBox.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
NATS Box Selector labels
*/}}
{{- define "natsBox.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nats.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: nats-box
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nats.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nats.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Print the image
*/}}
{{- define "nats.image" -}}
{{- $image := printf "%s:%s" .repository .tag }}
{{- if .registry }}
{{- $image = printf "%s/%s" .registry $image }}
{{- end }}
{{- $image -}}
{{- end }}

{{/*
translates env var map to list
*/}}
{{- define "nats.env" -}}
{{- range $k, $v := . }}
{{- if kindIs "string" $v }}
- name: {{ $k | quote }}
  value: {{ $v | quote }}
{{- else if kindIs "map" $v }}
- {{ merge (dict "name" $k) $v | toYaml | nindent 2 }}
{{- else }}
{{- fail (cat "env var" $k "must be string or map, got" (kindOf $v)) }}
{{- end }}
{{- end }}
{{- end }}

{{- /*
nats.loadMergePatch
input: map with 4 keys:
- file: name of file to load
- ctx: context to pass to tpl
- merge: interface{} to merge
- patch: []interface{} valid JSON Patch document
output: JSON encoded map with 1 key:
- doc: interface{} patched json result
*/}}
{{- define "nats.loadMergePatch" -}}
{{- $doc := tpl (.ctx.Files.Get (printf "files/%s" .file)) .ctx | fromYaml -}}
{{- $doc = mergeOverwrite $doc (deepCopy .merge) -}}
{{- get (include "jsonpatch" (dict "doc" $doc "patch" .patch) | fromJson ) "doc" | toYaml -}}
{{- end }}


{{- /*
nats.reloaderConfig
input: map with 2 keys:
- config: interface{} nats config
- dir: dir config file is in
output: YAML list of reloader config files
*/}}
{{- define "nats.reloaderConfig" -}}
  {{- $dir := trimSuffix "/" .dir -}}
  {{- with .config -}}
  {{- if kindIs "map" . -}}
    {{- range $k, $v := . -}}
      {{- if or (eq $k "cert_file") (eq $k "key_file") (eq $k "ca_file") }}
- config
- {{ $v }}
      {{- else if hasSuffix "$include" $k }}
- config
- {{ clean (printf "%s/%s" $dir $v) }}
      {{- else }}
        {{- include "nats.reloaderConfig" (dict "config" $v "dir" $dir) }}
      {{- end -}}
    {{- end -}}
  {{- end -}}
  {{- end -}}
{{- end -}}


{{- /*
nats.formatConfig
input: map[string]interface{}
output: string with following format rules
1. keys ending in $natsRaw are unquoted
2. keys ending in $natsInclude are converted to include directives
*/}}
{{- define "nats.formatConfig" -}}
  {{-
    (regexReplaceAll "\"<<\\s+(.*)\\s+>>\""
      (regexReplaceAll "\".*\\$include\": \"(.*)\",?" (include "toPrettyRawJson" .) "include ${1};")
    "${1}")
  -}}
{{- end -}}
