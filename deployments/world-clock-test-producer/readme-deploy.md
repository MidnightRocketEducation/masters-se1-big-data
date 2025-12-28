## Deploying

### Deploy World Clock Producer k8s Deployment

```zsh
kubectl apply -f deployments/world-clock-test-producer/world-clock-test-producer-deployment.yaml
```

### Deploy World Clock Producer k8s Service

```zsh
kubectl apply -f deployments/world-clock-test-producer/world-clock-test-producer-svc.yaml
```