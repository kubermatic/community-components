{{- define "kubeovn-gobetween-lb.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kubeovn-gobetween-lb.labels" -}}
app.kubernetes.io/name: kubeovn-gobetween-lb
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "kubeovn-gobetween-lb.selectorLabels" -}}
app: kubeovn-gobetween-lb
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}