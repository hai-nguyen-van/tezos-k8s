{{- define "tezos.localvars.pod_envvars" }}
- name: MY_POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP
- name: MY_POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: MY_POD_TYPE
  value: node
- name: MY_NODE_CLASS
  value: {{ .node_class }}
{{- end }}

{{- define "tezos.init_container.config_init" }}
{{- if include "tezos.shouldConfigInit" . }}
- image: "{{ .Values.images.tezos }}"
  command:
    - /bin/sh
  args:
    - "-c"
    - |
{{ tpl (.Files.Get "scripts/config-init.sh") . | indent 6 }}
  imagePullPolicy: IfNotPresent
  name: config-init
  volumeMounts:
    - mountPath: /etc/tezos
      name: config-volume
    - mountPath: /var/tezos
      name: var-volume
  envFrom:
    - configMapRef:
        name: tezos-config
  env:
{{- include "tezos.localvars.pod_envvars" . | indent 4 }}
{{- end }}
{{- end }}

{{- define "tezos.init_container.config_generator" }}
- image: {{ .Values.tezos_k8s_images.utils }}
  imagePullPolicy: IfNotPresent
  name: config-generator
  args:
    - "config-generator"
    - "--generate-config-json"
  envFrom:
    - secretRef:
        name: tezos-secret
    - configMapRef:
        name: tezos-config
  env:
{{- include "tezos.localvars.pod_envvars" . | indent 4 }}
  volumeMounts:
    - mountPath: /etc/tezos
      name: config-volume
    - mountPath: /var/tezos
      name: var-volume
{{- end }}

{{- define "tezos.init_container.wait_for_bootstrap" }}
{{- if include "tezos.shouldWaitForBootstrapNode" . }}
- image: {{ .Values.tezos_k8s_images.utils }}
  args:
    - wait-for-bootstrap
  imagePullPolicy: IfNotPresent
  name: wait-for-bootstrap
  envFrom:
    - configMapRef:
        name: tezos-config
  volumeMounts:
    - mountPath: /var/tezos
      name: var-volume
{{- end }}
{{- end }}

{{- define "tezos.init_container.snapshot_downloader" }}
{{- if include "tezos.shouldDownloadSnapshot" . }}
- image: "{{ .Values.tezos_k8s_images.utils }}"
  imagePullPolicy: IfNotPresent
  name: snapshot-downloader
  args:
    - snapshot-downloader
  volumeMounts:
    - mountPath: /var/tezos
      name: var-volume
    - mountPath: /etc/tezos
      name: config-volume
  envFrom:
    - configMapRef:
        name: tezos-config
  env:
{{- include "tezos.localvars.pod_envvars" . | indent 4 }}
{{- end }}
{{- end }}

{{- define "tezos.init_container.snapshot_importer" }}
{{- if include "tezos.shouldDownloadSnapshot" . }}
- image: "{{ .Values.images.tezos }}"
  imagePullPolicy: IfNotPresent
  name: snapshot-importer
  command:
    - /bin/sh
  args:
    - "-c"
    - |
{{ tpl (.Files.Get "scripts/snapshot-importer.sh") . | indent 6 }}
  volumeMounts:
    - mountPath: /var/tezos
      name: var-volume
    - mountPath: /etc/tezos
      name: config-volume
  envFrom:
    - configMapRef:
        name: tezos-config
  env:
{{- include "tezos.localvars.pod_envvars" . | indent 4 }}
{{- end }}
{{- end }}

{{- define "tezos.container.node" }}
{{- if has "tezedge" $.node_vals.runs | not }}
- command:
    - /bin/sh
  args:
    - "-c"
    - |
{{ tpl (.Files.Get "scripts/tezos-node.sh") . | indent 6 }}
  image: "{{ .Values.images.tezos }}"
  imagePullPolicy: IfNotPresent
  name: tezos-node
  ports:
    - containerPort: 8732
      name: tezos-rpc
    - containerPort: 9732
      name: tezos-net
  volumeMounts:
    - mountPath: /etc/tezos
      name: config-volume
    - mountPath: /var/tezos
      name: var-volume
{{- end }}
{{- end }}

{{- define "tezos.container.tezedge" }}
{{- if has "tezedge" $.node_vals.runs }}
- name: tezedge
  command:
    - /light-node
  args:
    - "--config-file=/etc/tezos/tezedge.conf"
  image: "{{ .Values.images.tezedge }}"
  imagePullPolicy: IfNotPresent
  ports:
    - containerPort: 8732
      name: tezos-rpc
    - containerPort: 9732
      name: tezos-net
  volumeMounts:
    - mountPath: /etc/tezos
      name: config-volume
    - mountPath: /var/tezos
      name: var-volume
{{- end }}
{{- end }}

{{- define "tezos.container.bakers" }}
{{- if has "baker" $.node_vals.runs }}
{{- range .Values.protocols }}
- image: "{{ $.Values.images.tezos }}"
  command:
    - /bin/sh
  args:
    - "-c"
    - |
{{- /*
Below set is a trick to get the range and global context. See:
https://github.com/helm/helm/issues/5979#issuecomment-518231758
*/}}
{{- $_ := set $ "command_in_tpl" .command }}
{{ tpl ($.Files.Get "scripts/baker-endorser.sh") $ | indent 6 }}
  imagePullPolicy: IfNotPresent
  name: baker-{{ lower .command }}
  volumeMounts:
    - mountPath: /etc/tezos
      name: config-volume
    - mountPath: /var/tezos
      name: var-volume
  envFrom:
    - configMapRef:
        name: tezos-config
  env:
{{- include "tezos.localvars.pod_envvars" $ | indent 4 }}
    - name: DAEMON
      value: baker
{{- end }}
{{- end }}
{{- end }}

{{- define "tezos.container.endorsers" }}
{{- if has "endorser" $.node_vals.runs }}
{{- range .Values.protocols }}
- image: "{{ $.Values.images.tezos }}"
  command:
    - /bin/sh
  args:
    - "-c"
    - |
{{- /*
Below set is a trick to get the range and global context. See:
https://github.com/helm/helm/issues/5979#issuecomment-518231758
*/}}
{{- $_ := set $ "command_in_tpl" .command }}
{{ tpl ($.Files.Get "scripts/baker-endorser.sh") $ | indent 6 }}
  imagePullPolicy: IfNotPresent
  name: endorser-{{ lower .command }}
  volumeMounts:
    - mountPath: /etc/tezos
      name: config-volume
    - mountPath: /var/tezos
      name: var-volume
  envFrom:
    - configMapRef:
        name: tezos-config
    - secretRef:
        name: tezos-secret
  env:
{{- include "tezos.localvars.pod_envvars" $ | indent 4 }}
    - name: DAEMON
      value: endorser
{{- end }}
{{- end }}
{{- end }}

{{- define "tezos.container.logger" }}
{{- if has "logger" $.node_vals.runs }}
- image: "{{ $.Values.tezos_k8s_images.utils }}"
  imagePullPolicy: IfNotPresent
  name: logger
  args:
    - "logger"
  envFrom:
    - secretRef:
        name: tezos-secret
    - configMapRef:
        name: tezos-config
  env:
{{- include "tezos.localvars.pod_envvars" . | indent 4 }}
  volumeMounts:
    - mountPath: /etc/tezos
      name: config-volume
    - mountPath: /var/tezos
      name: var-volume
{{- end }}
{{- end }}

{{- define "tezos.container.metrics" }}
{{- if has "metrics" $.node_vals.runs }}
- image: "registry.gitlab.com/nomadic-labs/tezos-metrics"
  args:
    - "--listen-prometheus=6666"
  imagePullPolicy: IfNotPresent
  name: metrics
  volumeMounts:
    - mountPath: /etc/tezos
      name: config-volume
    - mountPath: /var/tezos
      name: var-volume
  envFrom:
    - configMapRef:
        name: tezos-config
    - secretRef:
        name: tezos-secret
  env:
{{- include "tezos.localvars.pod_envvars" . | indent 4 }}
    - name: DAEMON
      value: tezos-metrics
{{- end }}
{{- end }}

{{/*
// * The zerotier containers:
*/}}

{{- define "tezos.init_container.zerotier" }}
{{- if (include "tezos.doesZerotierConfigExist" .) }}
- envFrom:
    - configMapRef:
        name: tezos-config
    - configMapRef:
        name: zerotier-config
  image: "{{ .Values.tezos_k8s_images.zerotier }}"
  imagePullPolicy: IfNotPresent
  name: get-zerotier-ip
  securityContext:
    capabilities:
      add:
        - NET_ADMIN
        - NET_RAW
        - SYS_ADMIN
    privileged: true
  volumeMounts:
    - mountPath: /etc/tezos
      name: config-volume
    - mountPath: /var/tezos
      name: var-volume
    - mountPath: /dev/net/tun
      name: dev-net-tun
  env:
{{- include "tezos.localvars.pod_envvars" . | indent 4 }}
{{- end }}
{{- end }}

{{- define "tezos.container.zerotier" }}
{{- if (include "tezos.doesZerotierConfigExist" .) }}
- args:
    - "-c"
    - "echo 'starting zerotier' && zerotier-one /var/tezos/zerotier"
  command:
    - sh
  image: "{{ .Values.tezos_k8s_images.zerotier }}"
  imagePullPolicy: IfNotPresent
  name: zerotier
  securityContext:
    capabilities:
      add:
        - NET_ADMIN
        - NET_RAW
        - SYS_ADMIN
    privileged: true
  volumeMounts:
    - mountPath: /var/tezos
      name: var-volume
{{- end }}
{{- end }}
