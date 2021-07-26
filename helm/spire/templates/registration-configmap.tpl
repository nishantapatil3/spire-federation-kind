apiVersion: v1
kind: ConfigMap
metadata:
  name: spire-entries
  namespace: {{ .Values.namespace }}
data:
  registration.json: |
    {
      "entries": [
        {
          "selectors": [
            {
              "type": "k8s_sat",
              "value": "agent_sa:spire-agent"
            }
          ],
          "spiffe_id": "spiffe://{{ .Values.trustDomain }}/spire-agent",
          "parent_id": "spiffe://{{ .Values.trustDomain }}/spire/server"
        },
        {
          "selectors": [
            {
              "type": "k8s",
              "value": "sa:connectivity-domain-operator-service-account"
            }
          ],
          "spiffe_id": "spiffe://{{ .Values.trustDomain }}/connectivity-domain-operator",
          "parent_id": "spiffe://{{ .Values.trustDomain }}/spire-agent"
        }
      ]
    }
