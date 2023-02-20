# create a eks cluster
eksctl create cluster --name eks-keda-scale --region us-west-1

aws eks describe-cluster --region us-west-1 --name eks-keda-scale --query "cluster.status"

# Delete eks cluster
eksctl delete cluster --name eks-keda-scale --region  us-west-1