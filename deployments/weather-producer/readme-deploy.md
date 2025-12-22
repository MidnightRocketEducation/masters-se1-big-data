## Deploying

### Deploy Weather Producer k8s Deployment

```zsh
kubectl apply -f deployments/weather-producer/weather-producer-deployment.yaml
```

### Deploy Weather Producer k8s Service

```zsh
kubectl apply -f deployments/weather-producer/weather-producer-svc.yaml
```

## Send payload to weather-producer

### How to curl
You can curl from any pod shell within the same k8s namespace.
- The pod must have curl installed.

### Start publishing weather data from source
If not setup otherwise data are here `/data`

```zsh
curl -X POST "http://weather-producer-svc:8080/api/v1/weather-producer/produce-from-path?path=/data"
```
