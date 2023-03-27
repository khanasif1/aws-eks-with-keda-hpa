#**********
#**KEDA****
#**********
# create a eks cluster
eksctl create cluster --name eks-keda-scale --region us-west-1

aws eks describe-cluster --region us-west-1 --name eks-keda-scale --query "cluster.status"

# Delete eks cluster
#eksctl delete cluster --name eks-keda-scale --region  us-west-1

#********************
#**KARPENTER*********
#Measuring KEDA against Karpenter
#********************
# create a eks cluster
eksctl create cluster --name eks-karpenter-scale --region us-west-1

aws eks describe-cluster --region us-west-1 --name eks-karpenter-scale --query "cluster.status"

# Delete eks cluster
eksctl delete cluster --name eks-keda-scale --region  us-west-1