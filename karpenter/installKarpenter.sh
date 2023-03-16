#Install Karpenter

# If you have login with docker in shell  execute below first
docker logout public.ecr.aws

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

#check and validate deployment

kubectl get all -n karpenter
kubectl get deployment -n karpenter
kubectl get deployment -n karpenter