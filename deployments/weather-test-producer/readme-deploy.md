## Deploying

### Deploy Weather Producer k8s Deployment

```zsh
kubectl apply -f deployments/weather-test-producer/weather-test-producer-deployment.yaml
```

### Deploy Weather Producer k8s Service

```zsh
kubectl apply -f deployments/weather-test-producer/weather-test-producer-svc.yaml
```