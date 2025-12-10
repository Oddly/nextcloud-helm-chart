# Nextcloud Helm Chart

A Helm chart for deploying [Nextcloud](https://nextcloud.com/) on Kubernetes using the [bjw-s app-template](https://github.com/bjw-s/helm-charts/tree/main/charts/library/common) library chart.

## Prerequisites

- Kubernetes 1.26+
- Helm 3.10+

## Dependencies

| Repository | Name | Version |
|------------|------|---------|
| https://bjw-s-labs.github.io/helm-charts/ | app-template | 3.7.3 |

## Installation

### Add the repository

```bash
helm repo add nextcloud-chart https://oddly.github.io/nextcloud-helm-chart
helm repo update
```

### Install the chart

```bash
helm install nextcloud nextcloud-chart/nextcloud -n nextcloud --create-namespace
```

Credentials are auto-generated on first install. Retrieve the admin password:

```bash
kubectl get secret nextcloud-credentials -n nextcloud -o jsonpath='{.data.admin-password}' | base64 -d
```

### Install from source

```bash
git clone https://github.com/Oddly/nextcloud-helm-chart.git
cd nextcloud-helm-chart
helm dependency update
helm install nextcloud . -n nextcloud --create-namespace
```

## Architecture

This chart deploys:

| Component | Type | Description |
|-----------|------|-------------|
| Nextcloud | Deployment | Main application (Apache) |
| PostgreSQL | Deployment | Database backend |
| Redis | Deployment | Session and cache store |
| Cron | CronJob | Background job runner (every 5 minutes) |

## Configuration

See [`values.yaml`](values.yaml) for default configuration and [`values-reference.yaml`](values-reference.yaml) for all available options.

### Minimal configuration

The default `values.yaml` provides a working deployment. Common customizations:

```yaml
# values-override.yaml
app-template:
  controllers:
    main:
      containers:
        main:
          env:
            NEXTCLOUD_TRUSTED_DOMAINS: "nextcloud.example.com localhost"

  ingress:
    main:
      enabled: true
      className: nginx
      annotations:
        cert-manager.io/cluster-issuer: letsencrypt-prod
        nginx.ingress.kubernetes.io/proxy-body-size: "16G"
      hosts:
        - host: nextcloud.example.com
          paths:
            - path: /
              pathType: Prefix
              service:
                identifier: main
                port: http
      tls:
        - secretName: nextcloud-tls
          hosts:
            - nextcloud.example.com
```

Install with overrides:

```bash
helm install nextcloud . -n nextcloud -f values-override.yaml
```

### Using an existing secret

To provide your own credentials instead of auto-generating:

```bash
kubectl create secret generic my-nextcloud-secret \
  --from-literal=admin-user=admin \
  --from-literal=admin-password=changeme \
  --from-literal=postgres-user=nextcloud \
  --from-literal=postgres-password=changeme \
  --from-literal=redis-password=changeme \
  -n nextcloud
```

Then reference it in your values:

```yaml
existingSecret: "my-nextcloud-secret"
```

### Gateway API (HTTPRoute)

For clusters using Gateway API instead of Ingress:

```yaml
app-template:
  route:
    main:
      enabled: true
      parentRefs:
        - name: my-gateway
          namespace: gateway-namespace
          sectionName: https
      hostnames:
        - "nextcloud.example.com"
      rules:
        - backendRefs:
            - name: main
              port: 80
```

### Storage

Default storage classes are used. To specify custom classes:

```yaml
app-template:
  persistence:
    data:
      storageClass: "my-storage-class"
      size: 500Gi
    postgresql-data:
      storageClass: "fast-ssd"
      size: 20Gi
```

## Upgrading

```bash
helm upgrade nextcloud . -n nextcloud
```

Credentials are preserved across upgrades.

## Uninstalling

```bash
helm uninstall nextcloud -n nextcloud
```

The credentials secret is retained by default. To remove everything:

```bash
helm uninstall nextcloud -n nextcloud
kubectl delete secret nextcloud-credentials -n nextcloud
kubectl delete pvc -l app.kubernetes.io/instance=nextcloud -n nextcloud
```

## Parameters

### Top-level parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `existingSecret` | Use an existing secret for credentials | `""` |
| `nextcloud.adminUser` | Admin username | `"admin"` |
| `nextcloud.adminPassword` | Admin password (auto-generated if empty) | `""` |
| `postgresql.user` | PostgreSQL username | `"nextcloud"` |
| `postgresql.password` | PostgreSQL password (auto-generated if empty) | `""` |
| `redis.password` | Redis password (auto-generated if empty) | `""` |

### app-template parameters

All parameters under `app-template:` are passed directly to the [bjw-s app-template](https://bjw-s.github.io/helm-charts/docs/app-template/) chart. Key parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `app-template.controllers.main.containers.main.image.tag` | Nextcloud image tag | `"30.0.2-apache"` |
| `app-template.controllers.main.containers.main.env.NEXTCLOUD_TRUSTED_DOMAINS` | Trusted domains | `"nextcloud.example.com localhost"` |
| `app-template.ingress.main.enabled` | Enable ingress | `false` |
| `app-template.persistence.data.size` | Nextcloud data volume size | `100Gi` |
| `app-template.persistence.postgresql-data.size` | PostgreSQL volume size | `10Gi` |

See [`values-reference.yaml`](values-reference.yaml) for the complete list of configurable parameters.

## Limitations

- **Single replica only**: Horizontal scaling requires shared storage (NFS/S3) and additional configuration
- **No automatic updates**: Nextcloud version upgrades require manual image tag changes and may need database migrations

## License

This chart is licensed under the [GNU General Public License v3.0](LICENSE).
