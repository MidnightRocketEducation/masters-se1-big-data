## Deploying

### Deploy Weather Producer k8s Deployment

```zsh
kubectl apply -f deployments/weather-test-producer/weather-test-producer-deployment.yaml
```

### Deploy Weather Producer k8s Service

```zsh
kubectl apply -f deployments/weather-test-producer/weather-test-producer-svc.yaml
```

## Send payload to weather-producer

### How to curl
You can curl from any pod shell within the same k8s namespace.
- The pod must have curl installed.

### Start publishing weather data from source
```zsh
curl -X POST http://weather-test-producer-svc:8080/api/v1/weather-producer/start-streaming
```

### Stop publishing weather data from source
```zsh
curl -X POST http://weather-test-producer-svc:8080/api/v1/weather-producer/stop-streaming
```

### Get streaiming status
```zsh
curl -X GET http://weather-test-producer-svc:8080/api/v1/weather-producer/streaming-stats
```

### Get current time in weather-producer
```zsh
curl -X GET http://weather-test-producer-svc:8080/api/v1/weather-producer/current-time
```

