cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      nodeSelector:
        intent: apps
      containers:
        - name: inflate
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.2
          resources:
            requests:
              cpu: 1
              memory: 1.5Gi
EOF


# Scale

kubectl scale deployment inflate --replicas 1
kubectl get deployment inflate 
kubectl scale deployment inflate --replicas 50
kubectl scale deployment inflate --replicas 0
#kubectl delete deployment inflate