apiVersion: v1
kind: Service
metadata:
  name: spire-server
  namespace: {{ .Values.namespace }}
spec:
  type: LoadBalancer
  ports:
    - name: grpc
      port: 8081
      targetPort: 8081
      protocol: TCP
    - name: federation-endpoint
      port: 8443
      targetPort: 8443
  selector:
    app: spire-server
