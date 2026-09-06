# Todo App

A tiny Flask + SQLite app used to practice **PersistentVolumes (PV)** and **PersistentVolumeClaims (PVC)** on GKE.

## Why the DB path is `/data`

The app writes to an absolute path:

```python
DB_PATH = "/data/todos.db"
```

This is deliberate. A PVC mounts at a `mountPath` you choose in the Kubernetes manifest. By hardcoding `/data/todos.db` in the app, the write target and the volume mount agree:

- Pod writes → `/data/todos.db`
- PVC mounts at `/data`
- Result: data lands on the persistent volume, not the pod's ephemeral layer.

If the path were relative (`./data/todos.db`), it would resolve to `/app/data/todos.db` (relative to the container `WORKDIR`) and the PVC would never be used.

## Build the image

```bash
cd live/main/todo-app
docker build -t todo-app:latest .
```

## Push to a registry

GKE cannot pull from your local Docker daemon, so push to a registry the cluster can reach.

```bash
# Resolve the current project id from gcloud config
export PROJECT_ID="$(gcloud config get-value project)"

# Artifact Registry (recommended)
docker tag todo-app:latest "asia-southeast2-docker.pkg.dev/${PROJECT_ID}/todo-app:latest"
docker push "asia-southeast2-docker.pkg.dev/${PROJECT_ID}/todo-app:latest"
```

> This avoids hardcoding the project id. Update the image name if you use a different registry.

## Deploy on GKE

The manifest needs three parts:

1. **PersistentVolumeClaim** — requests storage for the app's data.
2. **Deployment** — runs the app and mounts the PVC at `/data`.
3. **Service** — exposes the app.

Example `todo-app.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: todo-data
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: todo-app
  namespace: default
  labels:
    app: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: todo-app
  template:
    metadata:
      labels:
        app: todo-app
    spec:
      containers:
        - name: todo-app
          image: asia-southeast2-docker.pkg.dev/${PROJECT_ID}/todo-app:latest
          ports:
            - containerPort: 5000
          volumeMounts:
            - name: todo-data
              mountPath: /data
      volumes:
        - name: todo-data
          persistentVolumeClaim:
            claimName: todo-data
---
apiVersion: v1
kind: Service
metadata:
  name: todo-app
  namespace: default
spec:
  type: ClusterIP
  selector:
    app: todo-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
```

Apply it:

```bash
kubectl apply -f todo-app.yaml
```

## Verify persistence

Add a todo, then delete the pod:

```bash
kubectl delete pod -l app=todo-app
```

A new pod is recreated, and the todo should still be there — because the data lived on the PVC, not the pod.
