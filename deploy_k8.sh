#!/bin/bash

# Install K3s
curl -sfL https://get.k3s.io | sh -
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Create Kubernetes deployment YAML
cat <<EOF > k8s-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: node-app
  template:
    metadata:
      labels:
        app: node-app
    spec:
      containers:
      - name: node-app
        image: ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
        ports:
        - containerPort: 3000
        env:
        - name: DB_HOST
          value: "${DB_HOST}"
        - name: DB_USER
          value: "${DB_USER}"
        - name: DB_PASSWORD
          value: "${DB_PASS}"
        - name: DB_NAME
          value: "newDB"
EOF

# Create Service YAML
cat <<EOF > k8s-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: node-app-service
spec:
  type: LoadBalancer
  selector:
    app: node-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
EOF

# Apply to cluster
sudo kubectl apply -f k8s-deployment.yaml
sudo kubectl apply -f k8s-service.yaml
