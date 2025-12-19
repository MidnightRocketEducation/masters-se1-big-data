## Deploying

### Deploy World Clock Producer k8s Deployment

```zsh
kubectl apply -f deployments/world-clock-producer/world-clock-producer-deployment.yaml
```

### Deploy World Clock Producer k8s Service

```zsh
kubectl apply -f deployments/world-clock-producer/world-clock-producer-svc.yaml
```

## Send payload to world-clock-producer

### Change time speed
One hour within the application equals the specified number of real-life milliseconds.

```zsh
curl -X POST "http://world-clock-producer-svc:8080/api/v1/world-clock-producer/change-time-speed?one-hour-equals=1000"
```

