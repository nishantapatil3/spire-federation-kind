apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: spire-agent
  namespace: {{ .Values.namespace }}
  labels:
    app: spire-agent
spec:
  selector:
    matchLabels:
      app: spire-agent
  template:
    metadata:
      namespace: spire
      labels:
        app: spire-agent
    spec:
      hostPID: true
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: "spire-agent"
      initContainers:
        - name: init
          # This is a small image with wait-for-it, choose whatever image
          # you prefer that waits for a service to be up. This image is built
          # from https://github.com/lqhl/wait-for-it
          image: gcr.io/spiffe-io/wait-for-it
          args: ["-t", "30", "spire-server:8081"]
      containers:
        - name: spire-agent
          image: gcr.io/spiffe-io/spire-agent:0.11.3
          args: ["-config", "/run/spire/config/agent.conf"]
          volumeMounts:
            - name: spire-config
              mountPath: /run/spire/config
              readOnly: true
            - name: spire-agent-socket
              mountPath: /run/spire/sockets
              readOnly: false
            - name: spire-bundle
              mountPath: /run/spire/bundle
              readOnly: true
          livenessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - "/opt/spire/bin/spire-agent api fetch -socketPath /run/spire/sockets/agent.sock 2>&1 | grep -vqE 'connection refused|no such file or directory'"
            failureThreshold: 2
            initialDelaySeconds: 15
            periodSeconds: 60
            timeoutSeconds: 3
      volumes:
        - name: spire-config
          configMap:
            name: spire-agent
        - name: spire-bundle
          configMap:
            name: spire-bundle
        - name: spire-agent-socket
          hostPath:
            path: /run/spire/sockets
            type: DirectoryOrCreate
