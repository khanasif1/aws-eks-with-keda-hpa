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

kubectl create namespace -name karpenter-test

#############################
#******EKSCTL****************
#############################
#Create Service Account IAM
#eksctl create iamserviceaccount --name karpenter-service-account --region $REGION --namespace karpenter --cluster eks-karpenter-scale --role-name "karpenter-pod-role"  --attach-policy-arn arn:aws:iam::$account_id:policy/karpenter-sqs-policy --approve
#aws iam get-role --role-name karpenter-pod-role --query Role.AssumeRolePolicyDocument

#aws iam attach-role-policy --policy-arn arn:aws:iam::809980971988:policy/karpenter-dynamo-policy --role-name karpenter-sqs-role

#Check policies
#aws iam list-attached-role-policies --role-name karpenter-sqs-role --query AttachedPolicies[].PolicyArn --output text



#############################
#******AWS CLI****************
#############################
#Create service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: karpenter-service-account
  namespace: karpenter-test
EOF
kubectl apply -f my-service-account.yaml

$provide = $oidc_provider+":aud"
cat >trust-relationship.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::$account_id:oidc-provider/$oidc_provider"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "${oidc_provider}:aud": "sts.amazonaws.com",
            "${oidc_provider}:sub": "system:serviceaccount:$namespace:$service_account"
          }
        }
      }   
  ]
}
EOF

#Create role
aws iam create-role --role-name karpenter-pod-role --assume-role-policy-document file://trust-relationship.json --description "karpenter role-description"

#Attach policy to role SQS
aws iam attach-role-policy --role-name karpenter-pod-role --policy-arn=arn:aws:iam::$account_id:policy/karpenter-sqs-policy
#Attach policy to role Dynamo
aws iam attach-role-policy --role-name karpenter-pod-role --policy-arn=arn:aws:iam::$account_id:policy/karpenter-dynamo-policy

#Add role to K8s service account
kubectl annotate serviceaccount -n $namespace karpenter-service-account eks.amazonaws.com/role-arn=arn:aws:iam::$account_id":role/karpenter-pod-role"

aws iam get-role --role-name karpenter-pod-role  --query Role.AssumeRolePolicyDocument

aws iam list-attached-role-policies --role-name karpenter-pod-role --output text

export policy_arn=arn:aws:iam::809980971988:policy/karpenter-sqs-policy 

aws iam get-policy --policy-arn $policy_arn


aws iam get-policy-version --policy-arn $policy_arn --version-id v1


#Dummy test Configuring pods to use a Kubernetes service account
#=====================================================
cat >karpenter-pod-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: karpenter-app
spec:
  selector:
    matchLabels:
      app: karpenter-app
  template:
    metadata:
      labels:
        app: karpenter-app
    spec:
      serviceAccountName: karpenter-service-account
      containers:
      - name: karpenter-app
        image: public.ecr.aws/nginx/nginx:1.21
EOF

kubectl apply -f my-deployment.yaml

kubectl get pods | grep karpenter-app


kubectl get pods -n $namespace | grep karpenter-operator-5d9d4d7964-5gg5m

kubectl describe pod karpenter-operator-5d9d4d7964-5gg5m -n keda| grep AWS_ROLE_ARN:
kubectl describe pod karpenter-operator-metrics-apiserver-76cd79b8c6-42m4v -n keda| grep AWS_ROLE_ARN:

kubectl describe pod karpenter-operator-5d9d4d7964-5gg5m -n $namespace | grep AWS_WEB_IDENTITY_TOKEN_FILE:

kubectl get deploy -n $namespace 

kubectl describe deployment karpenter-operator -n $namespace | grep "Service Account"

kubectl describe deployment karpenter-operator-metrics-apiserver  -n $namespace | grep "Service Account"