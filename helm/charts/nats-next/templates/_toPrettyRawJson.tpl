{{- /*
toPrettyRawJson
input: interface{} valid JSON document
output: pretty raw JSON string
*/}}
{{- define "toPrettyRawJson" -}}
  {{-
    (regexReplaceAll "([^\\\\](?:\\\\\\\\)*)\\\\u003e"
      (regexReplaceAll "([^\\\\](?:\\\\\\\\)*)\\\\u003c"
        (regexReplaceAll "([^\\\\](?:\\\\\\\\)*)\\\\u0026" (toPrettyJson .) "${1}&")
      "${1}<")
    "${1}>")
  -}}
{{- end -}}
