# Kubernetes

Deployment into Kubernetes is simple using a [generic Helm chart for deploying web apps](https://github.com/benc-uk/helm-charts/tree/master/webapp)

Make sure you have [Helm installed first](https://helm.sh/docs/intro/install/)

First add the Helm repo
```bash
helm repo add benc-uk https://benc-uk.github.io/helm-charts
```

Edit `values.yaml` and modify the values to suit your environment.

```bash
helm install vuego-demoapp benc-uk/webapp --values values.yaml
```