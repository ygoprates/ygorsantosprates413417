# DEPLOYMENT.md

## 🚀 Deployment Guide

### Opção 1: Docker Compose (Desenvolvimento/Staging)

```bash
# 1. Build e iniciar
docker-compose up -d

# 2. Verificar status
docker-compose ps

# 3. Ver logs
docker-compose logs -f api

# 4. Parar
docker-compose down
```

### Opção 2: Kubernetes (Produção)

#### Pré-requisitos
- kubectl configurado
- Cluster Kubernetes rodando
- Docker Registry (Docker Hub, ECR, etc.)

#### Passos

##### 1. Build e Push da Imagem

```bash
# Build da imagem
docker build -t your-registry/artists-api:1.0.0 .

# Push para registry
docker push your-registry/artists-api:1.0.0
```

##### 2. Criar ConfigMap (Configurações)

```bash
kubectl create configmap artists-config \
  --from-literal=SPRING_PROFILES_ACTIVE=prod \
  --from-literal=LOGGING_LEVEL_ROOT=WARN \
  --from-literal=LOGGING_LEVEL_COM_ARTISTS=INFO
```

##### 3. Criar Secrets (Dados Sensíveis)

```bash
kubectl create secret generic artists-secrets \
  --from-literal=SPRING_DATASOURCE_USERNAME=postgres \
  --from-literal=SPRING_DATASOURCE_PASSWORD=your-secure-password \
  --from-literal=JWT_SECRET=your-very-long-secret-key \
  --from-literal=MINIO_ACCESS_KEY=your-minio-key \
  --from-literal=MINIO_SECRET_KEY=your-minio-secret
```

##### 4. Criar Namespaces

```bash
kubectl create namespace artists-api
```

##### 5. Aplicar Manifests Kubernetes

```yaml
# postgres-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: artists-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:16-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: artists_db
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: artists-secrets
              key: SPRING_DATASOURCE_USERNAME
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: artists-secrets
              key: SPRING_DATASOURCE_PASSWORD
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
# postgres-service.yml
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: artists-api
spec:
  selector:
    app: postgres
  ports:
  - protocol: TCP
    port: 5432
    targetPort: 5432
  type: ClusterIP
---
# postgres-pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: artists-api
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: standard
```

```yaml
# minio-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: minio
  namespace: artists-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: minio
  template:
    metadata:
      labels:
        app: minio
    spec:
      containers:
      - name: minio
        image: minio/minio:latest
        args:
        - server
        - /data
        - --console-address
        - :9001
        ports:
        - containerPort: 9000
        - containerPort: 9001
        env:
        - name: MINIO_ROOT_USER
          valueFrom:
            secretKeyRef:
              name: artists-secrets
              key: MINIO_ACCESS_KEY
        - name: MINIO_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: artists-secrets
              key: MINIO_SECRET_KEY
        volumeMounts:
        - name: minio-storage
          mountPath: /data
      volumes:
      - name: minio-storage
        persistentVolumeClaim:
          claimName: minio-pvc
---
# minio-service.yml
apiVersion: v1
kind: Service
metadata:
  name: minio
  namespace: artists-api
spec:
  selector:
    app: minio
  ports:
  - name: api
    protocol: TCP
    port: 9000
    targetPort: 9000
  - name: console
    protocol: TCP
    port: 9001
    targetPort: 9001
  type: LoadBalancer
---
# minio-pvc.yml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: minio-pvc
  namespace: artists-api
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
  storageClassName: standard
```

```yaml
# api-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: artists-api
  namespace: artists-api
spec:
  replicas: 3  # 3 réplicas para alta disponibilidade
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: artists-api
  template:
    metadata:
      labels:
        app: artists-api
    spec:
      containers:
      - name: artists-api
        image: your-registry/artists-api:1.0.0
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          valueFrom:
            configMapKeyRef:
              name: artists-config
              key: SPRING_PROFILES_ACTIVE
        - name: SPRING_DATASOURCE_URL
          value: jdbc:postgresql://postgres:5432/artists_db
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: artists-secrets
              key: SPRING_DATASOURCE_USERNAME
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: artists-secrets
              key: SPRING_DATASOURCE_PASSWORD
        - name: MINIO_URL
          value: http://minio:9000
        - name: MINIO_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: artists-secrets
              key: MINIO_ACCESS_KEY
        - name: MINIO_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: artists-secrets
              key: MINIO_SECRET_KEY
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: artists-secrets
              key: JWT_SECRET
        - name: LOGGING_LEVEL_ROOT
          valueFrom:
            configMapKeyRef:
              name: artists-config
              key: LOGGING_LEVEL_ROOT
        - name: LOGGING_LEVEL_COM_ARTISTS
          valueFrom:
            configMapKeyRef:
              name: artists-config
              key: LOGGING_LEVEL_COM_ARTISTS
        
        # Liveness Probe (Kubernetes reinicia se falhar)
        livenessProbe:
          httpGet:
            path: /api/v1/health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Readiness Probe (Remove do load balancer se falhar)
        readinessProbe:
          httpGet:
            path: /api/v1/health/ready
            port: 8080
          initialDelaySeconds: 20
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # Resource Limits
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        
        # Security Context
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          readOnlyRootFilesystem: false
      
      # Affinity - Distribuir pods em diferentes nodes
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - artists-api
              topologyKey: kubernetes.io/hostname
---
# api-service.yml
apiVersion: v1
kind: Service
metadata:
  name: artists-api-service
  namespace: artists-api
  labels:
    app: artists-api
spec:
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  selector:
    app: artists-api
---
# api-hpa.yml (Horizontal Pod Autoscaling)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: artists-api-hpa
  namespace: artists-api
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: artists-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

##### 6. Aplicar Manifests

```bash
# Criar namespace
kubectl create namespace artists-api

# Criar ConfigMap e Secrets
kubectl create configmap artists-config \
  --from-literal=SPRING_PROFILES_ACTIVE=prod \
  --from-literal=LOGGING_LEVEL_ROOT=WARN \
  --from-literal=LOGGING_LEVEL_COM_ARTISTS=INFO \
  -n artists-api

kubectl create secret generic artists-secrets \
  --from-literal=SPRING_DATASOURCE_USERNAME=postgres \
  --from-literal=SPRING_DATASOURCE_PASSWORD=your-password \
  --from-literal=JWT_SECRET=your-secret \
  --from-literal=MINIO_ACCESS_KEY=your-key \
  --from-literal=MINIO_SECRET_KEY=your-secret \
  -n artists-api

# Aplicar manifests
kubectl apply -f postgres-deployment.yml
kubectl apply -f minio-deployment.yml
kubectl apply -f api-deployment.yml
kubectl apply -f api-hpa.yml
```

##### 7. Verificar Deployment

```bash
# Ver status dos pods
kubectl get pods -n artists-api

# Ver serviços
kubectl get svc -n artists-api

# Ver logs
kubectl logs -f deployment/artists-api -n artists-api

# Descrever recursos
kubectl describe pod <pod-name> -n artists-api
```

### Opção 3: Cloud Providers

#### AWS ECS + RDS

```json
{
  "family": "artists-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "artists-api",
      "image": "your-registry/artists-api:1.0.0",
      "portMappings": [{"containerPort": 8080}],
      "environment": [
        {
          "name": "SPRING_DATASOURCE_URL",
          "value": "jdbc:postgresql://artists-db.xxx.rds.amazonaws.com:5432/artists_db"
        }
      ],
      "secrets": [
        {
          "name": "SPRING_DATASOURCE_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:artists-db-password"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/artists-api",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

#### Google Cloud Run

```bash
# Build e push
gcloud builds submit --tag gcr.io/PROJECT_ID/artists-api

# Deploy
gcloud run deploy artists-api \
  --image gcr.io/PROJECT_ID/artists-api \
  --platform managed \
  --region us-central1 \
  --set-env-vars SPRING_DATASOURCE_URL=jdbc:postgresql://cloudsql-connection \
  --add-cloudsql-instances PROJECT_ID:us-central1:artists-db
```

### CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
name: Deploy to Kubernetes

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build with Maven
        run: mvn clean package -DskipTests
      
      - name: Build Docker image
        run: docker build -t artists-api:${{ github.sha }} .
      
      - name: Push to registry
        run: |
          docker tag artists-api:${{ github.sha }} ${{ secrets.REGISTRY }}/artists-api:${{ github.sha }}
          docker push ${{ secrets.REGISTRY }}/artists-api:${{ github.sha }}
      
      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/artists-api \
            artists-api=${{ secrets.REGISTRY }}/artists-api:${{ github.sha }} \
            -n artists-api
```

## 🔄 Backup e Restore

### PostgreSQL Backup

```bash
# Backup
kubectl exec -it pod/postgres-xxx -n artists-api -- \
  pg_dump -U postgres artists_db > backup.sql

# Restore
kubectl exec -i pod/postgres-xxx -n artists-api -- \
  psql -U postgres artists_db < backup.sql
```

### MinIO Backup

```bash
# Listar objetos
mc ls minio-alias/albums

# Copiar bucket
mc cp --recursive minio-alias/albums /local/backup
```

## 🔒 Security Checklist

- [ ] JWT_SECRET alterado e seguro
- [ ] Senhas de banco alteradas
- [ ] CORS restrito a domínios conhecidos
- [ ] HTTPS/TLS habilitado
- [ ] Secrets armazenados em secret manager
- [ ] Rate limiting configurado
- [ ] Logs centralizados
- [ ] Backups automáticos
- [ ] Monitoramento habilitado

## 📊 Monitoramento

### Prometheus Metrics

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: artists-api
spec:
  selector:
    matchLabels:
      app: artists-api
  endpoints:
  - port: metrics
    interval: 30s
    path: /actuator/prometheus
```

### Alertas Recomendados

- Pod restart rate > 0
- Memory usage > 80%
- CPU usage > 80%
- HTTP error rate > 1%
- Response time > 500ms
- Database connection errors

---

**Para mais informações, consulte o README.md**
