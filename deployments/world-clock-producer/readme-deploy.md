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

### Hot to curl
You can curl from any pod shell within the same k8s namespace.
- The pod must have curl installed.

### Change time speed
One hour within the application equals the specified number of real-life milliseconds.

```zsh
curl -X POST "http://world-clock-producer-svc:8080/api/v1/world-clock-producer/change-time-speed?one-hour-equals=<milliseconds>"
```

### Change / reset date and time
Change the current date and time used by the world-clock-producer. It will continue publishing time from this new date onwards.

```zsh
curl -X POST \
  -H "Content-Type: application/json" \
  -d "\"2011-01-02T09:31:00Z\"" \
  http://localhost:8080/api/v1/world-clock-producer/change-current-time
```
