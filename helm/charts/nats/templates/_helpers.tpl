{{/*
Expand the name of the chart.
*/}}
{{- define "nats.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "nats.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "nats.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nats.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nats.labels" -}}
helm.sh/chart: {{ include "nats.chart" . }}
{{- range $name, $value := .Values.commonLabels }}
{{ $name }}: {{ tpl $value $ }}
{{- end }}
{{ include "nats.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nats.selectorLabels" -}}
{{- if .Values.nats.selectorLabels }}
{{ tpl (toYaml .Values.nats.selectorLabels) . }}
{{- else }}
app.kubernetes.io/name: {{ include "nats.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- end }}


{{/*
Return the proper NATS image name
*/}}
{{- define "nats.clusterAdvertise" -}}
{{- if $.Values.useFQDN }}
{{- printf "$(POD_NAME).%s.$(POD_NAMESPACE).svc.%s" (include "nats.fullname" . ) $.Values.k8sClusterDomain }}
{{- else }}
{{- printf "$(POD_NAME).%s.$(POD_NAMESPACE)" (include "nats.fullname" . ) }}
{{- end }}
{{- end }}

{{/*
Return the NATS cluster routes.
*/}}
{{- define "nats.clusterRoutes" -}}
{{- $name := (include "nats.fullname" . ) -}}
{{- $namespace := (include "nats.namespace" . ) -}}
{{- range $i, $e := until (.Values.cluster.replicas | int) -}}
{{- if $.Values.useFQDN }}
{{- printf "nats://%s-%d.%s.%s.svc.%s:6222," $name $i $name $namespace $.Values.k8sClusterDomain -}}
{{- else }}
{{- printf "nats://%s-%d.%s.%s:6222," $name $i $name $namespace -}}
{{- end }}
{{- end -}}
{{- end }}

{{- define "nats.extraRoutes" -}}
{{- range $i, $url := .Values.cluster.extraRoutes -}}
{{- printf "%s," $url -}}
{{- end -}}
{{- end }}

{{- define "nats.tlsConfig" -}}
tls {
{{- if .cert }}
    cert_file: {{ .secretPath }}/{{ .secret.name }}/{{ .cert }}
{{- end }}
{{- if .key }}
    key_file:  {{ .secretPath }}/{{ .secret.name }}/{{ .key }}
{{- end }}
{{- if .ca }}
    ca_file: {{ .secretPath }}/{{ .secret.name }}/{{ .ca }}
{{- end }}
{{- if .insecure }}
    insecure: {{ .insecure }}
{{- end }}
{{- if .verify }}
    verify: {{ .verify }}
{{- end }}
{{- if .verifyAndMap }}
    verify_and_map: {{ .verifyAndMap }}
{{- end }}
{{- if .curvePreferences }}
    curve_preferences: {{ .curvePreferences }}
{{- end }}
{{- if .timeout }}
    timeout: {{ .timeout }}
{{- end }}
{{- if .cipherSuites }}
    cipher_suites: {{ toRawJson .cipherSuites }}
{{- end }}
}
{{- end }}

{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "networkPolicy.apiVersion" -}}
{{- if semverCompare ">=1.4-0, <1.7-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "extensions/v1beta1" -}}
{{- else -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Renders a value that contains template.
Usage:
{{ include "tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "tplvalues.render" -}}
  {{- if typeIs "string" .value }}
    {{- tpl .value .context }}
  {{- else }}
    {{- tpl (.value | toYaml) .context }}
  {{- end }}
{{- end -}}
