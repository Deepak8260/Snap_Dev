# Kubernetes Orchestration & Cluster Manifests

This module documents the Kubernetes manifests and multi-node **Kind (Kubernetes in Docker)** cluster specification for container orchestration in **SnapDev**.

---

## Technical File Audit

| Manifest File | Kind / API Version | Kubernetes Resource | Key Configurations |
| --- | --- | --- | --- |
| [`config.yml`](config.yml) | `kind.x-k8s.io/v1alpha4` | `Cluster` | 3 Nodes (1 Control Plane, 2 Worker Nodes).<br>Port Mapping: `30080:30080`. |
| [`namespace.yml`](namespace.yml) | `v1` | `Namespace` | Logical boundary: `snapdev-ns`. |
| [`deployment.yml`](deployment.yml) | `apps/v1` | `Deployment` | Replicas: `5`.<br>Image: `kumar3472/snapdev:latest`.<br>Selector: `app: snapdev-label`. |
| [`service.yml`](service.yml) | `v1` | `Service` (`NodePort`) | Cluster Port: `5000`.<br>Target Container Port: `5000`.<br>NodePort: `30080`. |

---

## Deep Dive: Manifest Code Specifications

### 1. Kind Multi-Node Cluster Spec (`config.yml`)

The manifest [`config.yml`](config.yml) provisions a multi-node Kubernetes cluster using Docker containers:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 30080
        protocol: TCP

  - role: worker

  - role: worker
```

#### Technical Rationale:
- **Multi-Node Architecture**: Simulates a production cluster by launching 1 Control Plane node (running `kube-apiserver`, `etcd`, `kube-scheduler`, `kube-controller-manager`) and 2 Worker nodes (running `kubelet` and `containerd`).
- **`extraPortMappings`**: Maps host machine port `30080` to the Control Plane container port `30080`. This allows external traffic arriving at the EC2 instance on port `30080` to pass directly to the Kubernetes NodePort service.

---

### 2. Namespace Manifest (`namespace.yml`)

The manifest [`namespace.yml`](namespace.yml) creates an isolated tenant environment:

```yaml
apiVersion: v1

kind: Namespace

metadata:
  name: snapdev-ns
```

---

### 3. Replicated Deployment Manifest (`deployment.yml`)

The manifest [`deployment.yml`](deployment.yml) maintains high availability by running 5 pod replicas distributed across the 2 worker nodes:

```yaml
apiVersion: apps/v1

kind: Deployment

metadata:
  name: snapdev-deployment
  namespace: snapdev-ns
  labels:
    app: snapdev-label

spec:
  replicas: 5
  selector:
    matchLabels:
      app: snapdev-label

  template:
    metadata:
      name: snapdev-pod
      namespace: snapdev-ns
      labels:
        app: snapdev-label

    spec:
      containers:
        - name: snapdev-cont
          image: kumar3472/snapdev:latest
          ports:
            - containerPort: 5000
```

#### Technical Rationale:
- `replicas: 5`: Ensures high availability. If a worker node fails, Kubernetes automatically reschedules missing pods onto surviving worker nodes.
- `matchLabels`: Loose-coupling mechanism allowing the Deployment controller to select and manage Pods matching `app: snapdev-label`.

---

### 4. NodePort Ingress Service Manifest (`service.yml`)

The manifest [`service.yml`](service.yml) balances traffic across all 5 pods:

```yaml
apiVersion: v1

kind: Service

metadata:
  name: snapdev-svc
  namespace: snapdev-ns

spec:
  type: NodePort
  selector:
    app: snapdev-label

  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
      nodePort: 30080
```

#### Port Mapping Breakdown:
- `port: 5000`: Internal cluster IP service port accessible within the Kubernetes cluster.
- `targetPort: 5000`: Container port exposed by Flask (`app.py`).
- `nodePort: 30080`: Static port opened on every Kubernetes cluster node, routing external requests to `snapdev-svc`.

---

## Step-by-Step CLI Commands

```bash
# 1. Create 3-Node Kind Cluster
kind create cluster --config k8s/config.yml --name snapdev-cluster

# 2. Deploy Namespace, Deployment, and Service
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/deployment.yml
kubectl apply -f k8s/service.yml

# 3. Verify Pod Status and Node Distribution across snapdev-ns
kubectl get pods -n snapdev-ns -o wide

# 4. Scale Deployment to 10 Replicas dynamically
kubectl scale deployment/snapdev-deployment --replicas=10 -n snapdev-ns

# 5. Inspect Service NodePort binding
kubectl get svc -n snapdev-ns

# 6. Delete Kind Cluster when done
kind delete cluster --name snapdev-cluster
```
