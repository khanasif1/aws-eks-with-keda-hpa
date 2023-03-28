# Instances launched by Karpenter must run with an InstanceProfile that grants permissions necessary to run containers and configure networking.
export AWS_REGION=us-west-1 
aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${REGION}
# If you have login with docker in shell  execute below first
docker logout public.ecr.aws

TEMPOUT=$(mktemp)

curl -fsSL https://karpenter.sh/"${KARPENTER_VERSION}"/getting-started/getting-started-with-eksctl/cloudformation.yaml  > $TEMPOUT \
&& aws cloudformation deploy \
  --stack-name "Karpenter-${CLUSTER_NAME}" \
  --template-file "${TEMPOUT}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "ClusterName=${CLUSTER_NAME}" \
  --region ${REGION}


#grant access to instances using the profile to connect to the cluster. This command adds the Karpenter node role to your aws-auth configmap, 
#allowing nodes with this role to connect to the cluster.

eksctl create iamidentitymapping \
  --username system:node:{{EC2PrivateDNSName}} \
  --cluster  ${CLUSTER_NAME} \
  --arn "arn:aws:iam::${ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}" \
  --group system:bootstrappers \
  --group system:nodes 
  
kubectl describe configmap -n kube-system aws-auth

#KarpenterController IAM Role
eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve


#Karpenter requires permissions like launching instances. 
#This will create an AWS IAM Role, Kubernetes service account, and associate them using IAM Roles for Service Accounts (IRSA)

eksctl create iamserviceaccount \
  --cluster "${CLUSTER_NAME}" --name karpenter --namespace karpenter \
  --role-name "Karpenter-${CLUSTER_NAME}" \
  --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/KarpenterControllerPolicy-${CLUSTER_NAME}" \
  --role-only \
  --approve

export KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/Karpenter-${CLUSTER_NAME}"


#EC2 Spot Linked Role

#This step is only necessary if this is the first time you’re using EC2 Spot in this account. 
#If the role has already been successfully created, you will see: An error occurred 

aws iam create-service-linked-role --aws-service-name spot.amazonaws.com 2> /dev/null || echo 'Already exist'

#Install Karpenter Helm Chart
#Install the chart passing in the cluster details and the Karpenter role ARN.

export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output text)"
helm upgrade --install --namespace karpenter --create-namespace \
  karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version ${KARPENTER_VERSION} \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
  --set settings.aws.clusterName=${CLUSTER_NAME} \
  --set settings.aws.clusterEndpoint=${CLUSTER_ENDPOINT} \
  --set defaultProvisioner.create=false \
  --set settings.aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${CLUSTER_NAME} \
  --set settings.aws.interruptionQueueName=${CLUSTER_NAME} \
  --wait

kubectl get all -n karpenter
kubectl get deployment -n karpenter
kubectl get pods --namespace karpenter
