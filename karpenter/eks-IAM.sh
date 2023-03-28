#=========================================================================
#https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html
#========================================================================

account_id=$(aws sts get-caller-identity --query "Account" --output text)
oidc_provider=$(aws eks describe-cluster --name eks-karpenter-scale --region $REGION --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")
#KARPENTER PODS
export namespace=karpenter-test
export service_account=karpenter-service-account

kubectl config set-context –current –namespace=keda
#Configuring a Kubernetes service account to assume an IAM role

# Create Policy to access AWS SQS Services
cat >my-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sqs:*",
            "Resource": "*"
        }
    ]
}
EOF
aws iam create-policy --policy-name karpenter-sqs-policy --policy-document file://my-policy.json

# Create Policy to access AWS Dynamo Services
cat >dynamo-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "dynamodb:*",
            "Resource": "*"
        }
    ]
}
EOF
aws iam create-policy --policy-name karpenter-dynamo-policy --policy-document file://dynamo-policy.json

# Create Service Account IAM
#eksctl create iamserviceaccount --name karpenter-service-account --region $REGION --namespace karpenter --cluster eks-karpenter-scale --role-name "karpenter-pod-role"  --attach-policy-arn arn:aws:iam::$account_id:policy/karpenter-sqs-policy --approve
aws iam get-role --role-name karpenter-pod-role --query Role.AssumeRolePolicyDocument

aws iam attach-role-policy --policy-arn arn:aws:iam::809980971988:policy/karpenter-dynamo-policy --role-name karpenter-sqs-role

#Check policies
aws iam list-attached-role-policies --role-name karpenter-sqs-role --query AttachedPolicies[].PolicyArn --output text
######Pending
kubectl create namespace -name karpenter-test
#Create service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: karpenter-service-account
  namespace: karpenter-test
EOF
kubectl apply -f my-service-account.yaml

cat >trust-relationship.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::$account_id:oidc-provider/$oidc_provider"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "$oidc_provider: aud": "sts.amazonaws.com",
            "$oidc_provider: sub": "system:serviceaccount:$namespace:$service_account"
          }
        }
      }
    }
  ]
}
EOF

aws iam create-role --role-name keda-role --assume-role-policy-document file://trust-relationship1.json --description "karpenter role-description"

aws iam attach-role-policy --role-name keda-role --policy-arn=arn:aws:iam::809980971988:policy/keda-sqs-policy

aws iam attach-role-policy --role-name keda-role --policy-arn=arn:aws:iam::809980971988:policy/keda-dynamo-policy

kubectl annotate serviceaccount -n keda karpenter-service-account eks.amazonaws.com/role-arn=arn:aws:iam::$account_id:role/karpenter-role

aws iam get-role --role-name keda-role  --query Role.AssumeRolePolicyDocument

aws iam list-attached-role-policies --role-name keda-role --output text

export policy_arn=arn:aws:iam::809980971988:policy/keda-sqs-policy 

aws iam get-policy --policy-arn $policy_arn


aws iam get-policy-version --policy-arn $policy_arn --version-id v1

#Dummy test Configuring pods to use a Kubernetes service account
#=====================================================
cat >keda-pod-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keda-app
spec:
  selector:
    matchLabels:
      app: keda-app
  template:
    metadata:
      labels:
        app: keda-app
    spec:
      serviceAccountName: keda-service-account
      containers:
      - name: keda-app
        image: public.ecr.aws/nginx/nginx:1.21
EOF

kubectl apply -f my-deployment.yaml

kubectl get pods | grep keda-app


kubectl get pods -n keda | grep keda-operator-5d9d4d7964-5gg5m

kubectl describe pod keda-operator-5d9d4d7964-5gg5m -n keda| grep AWS_ROLE_ARN:
kubectl describe pod keda-operator-metrics-apiserver-76cd79b8c6-42m4v -n keda| grep AWS_ROLE_ARN:

kubectl describe pod keda-operator-5d9d4d7964-5gg5m -n keda | grep AWS_WEB_IDENTITY_TOKEN_FILE:

kubectl get deploy -n keda 

kubectl describe deployment keda-operator -n keda | grep "Service Account"

kubectl describe deployment keda-operator-metrics-apiserver  -n keda | grep "Service Account"