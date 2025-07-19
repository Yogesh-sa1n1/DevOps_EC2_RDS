#!/bin/bash
sudo apt update -y
sudo apt install -y mysql-client-core-8.0 git curl ca-certificates gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

cd /home/ubuntu

DB_HOST="${DB_HOST}"
DB_USER="${DB_USER}"
DB_PASS="${DB_PASS}"

sudo mysql -h "$DB_HOST" -P 3306 -u "$DB_USER" -p"$DB_PASS" <<EOSQL
CREATE DATABASE IF NOT EXISTS newDB;
USE newDB;
CREATE TABLE IF NOT EXISTS employees (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(100),
  department VARCHAR(50)
);
EOSQL

# git clone https://github.com/Yogesh-sa1n1/EC2_RDS_Connection.git
# cd EC2_RDS_Connection
#sudo docker build -t my-node-app .
# sudo docker run -d -p 3000:3000 --name node-container \
#   -e DB_HOST="$DB_HOST" \
#   -e DB_USER="$DB_USER" \
#   -e DB_PASSWORD="$DB_PASS" \
#   -e DB_NAME="newDB" \
#   my-node-app

if [ -d "EC2_RDS_Connection" ]; then
  sudo rm -rf EC2_RDS_Connection
fi
git clone https://github.com/Yogesh-sa1n1/EC2_RDS_Connection.git || { echo "Git clone failed"; exit 1; }
cd EC2_RDS_Connection || { echo "Failed to cd into project directory"; exit 1; }

# DOCKER_USERNAME="${DOCKER_USERNAME}"
# DOCKER_PASSWORD="${DOCKER_PASSWORD}"
IMAGE_NAME="${IMAGE_NAME}"
IMAGE_TAG="${IMAGE_TAG}"


# Export Docker credentials
export DOCKER_USERNAME="${DOCKER_USERNAME}"
export DOCKER_PASSWORD="${DOCKER_PASSWORD}"

# Login with sudo and env preserved
echo "${DOCKER_PASSWORD}" | sudo -E docker login -u "${DOCKER_USERNAME}" --password-stdin

sudo docker build -t "${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}" .
sudo docker push "${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"



# Install k3s
curl -sfL https://get.k3s.io | sh -
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml


# Create K8s Deployment YAML
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

# Deploy to K8s
sudo kubectl apply -f k8s-deployment.yaml
sudo kubectl apply -f k8s-service.yaml



