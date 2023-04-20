#**********
#**KEDA****
#**********
# create a eks cluster
eksctl create cluster --name eks-keda-scale --region ${AWS_REGION}

aws eks describe-cluster --region ${AWS_REGION} --name eks-keda-scale --query "cluster.status"

# Delete eks cluster
#eksctl delete cluster --name eks-keda-scale --region  us-west-1

#********************
#**KARPENTER*********
#Measuring KEDA against Karpenter
#********************
# 2. create a eks cluster
eksctl create cluster --name ${CLUSTER_NAME} --region ${AWS_REGION}

aws eks describe-cluster --region ${AWS_REGION} --name eks-karpenter-scale --query "cluster.status"

# Delete eks cluster
eksctl delete cluster --name eks-keda-scale --region  ${AWS_REGION}