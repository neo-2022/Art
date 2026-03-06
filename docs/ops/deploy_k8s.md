# Deploy k8s

## Source of truth
- `formats/platform_support.yaml`
- `docs/ops/platform-container-k8s-testing.md`
- `docs/source/checklists/CHECKLIST_37_LINUX_PROD_HARDENING_TIER_A_B.md`

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

## Проверка в platform matrix
- Validate/execute smoke path определяется через `tests/platform/k8s/run_k8s_smoke.sh`.
- Kubernetes рассматривается как обязательная test platform наравне с Linux/VM/Docker.
