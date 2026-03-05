# Deploy k8s

## cert-manager
Единственный способ выдачи/ротации сертификатов: cert-manager.

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: art-ca
```

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: art-cert
spec:
  secretName: art-tls
```
Ingress/Gateway использует secret `art-tls`.
Ротация выполняется автоматически без простоя.
