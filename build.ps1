# Build script for Big Data Ecosystem components

Write-Host "🚀 Building Big Data Ecosystem Docker images..."

# Build MLflow server image
Write-Host "📦 Building MLflow server image..."
Set-Location -Path "$PSScriptRoot\mlflow"
try {
    & docker build -t mlflow-server:latest .
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ MLflow server image built successfully!"
    } else {
        Write-Host "❌ MLflow server build failed!"
        exit 1
    }
} catch {
    Write-Host "❌ Error building MLflow server: $_"
    exit 1
}

# Build Spark Streaming image
Write-Host "📦 Building Spark Streaming image..."
Set-Location -Path "$PSScriptRoot\spark"
try {
    # First build the JAR with Maven
    & mvn clean package -DskipTests
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Maven build successful!"

        # Then build Docker image
        & docker build -t spark-streaming-ml:latest .
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Spark Streaming image built successfully!"
        } else {
            Write-Host "❌ Spark Streaming Docker build failed!"
            exit 1
        }
    } else {
        Write-Host "❌ Maven build failed!"
        exit 1
    }
} catch {
    Write-Host "❌ Error building Spark Streaming: $_"
    exit 1
}

Set-Location -Path $PSScriptRoot
Write-Host ""
Write-Host "🎉 All Docker images built successfully!"
Write-Host ""
Write-Host "📋 Next steps:"
Write-Host "  1. Push images to registry if needed: docker push mlflow-server:latest && docker push spark-streaming-ml:latest"
Write-Host "  2. Run deployment: .\deploy.ps1"