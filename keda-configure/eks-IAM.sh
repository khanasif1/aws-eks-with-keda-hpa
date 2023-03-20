#=========================================================================
#https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html
#========================================================================
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
            "Resource": "arn:aws:sqs:us-west-1:809980971988:keda-queue"
        }
    ]
}
EOF
aws iam create-policy --policy-name keda-sqs-policy --policy-document file://my-policy.json

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
aws iam create-policy --policy-name keda-dynamo-policy --policy-document file://dynamo-policy.json

# Create Service Account IAM
eksctl create iamserviceaccount --name keda-service-account --region us-west-1 --namespace keda --cluster eks-keda-scale --role-name "keda-sqs-role"  --attach-policy-arn arn:aws:iam::809980971988:policy/keda-sqs-policy --approve
aws iam get-role --role-name keda-sqs-role --query Role.AssumeRolePolicyDocument
#Check policies
aws iam list-attached-role-policies --role-name keda-sqs-role --query AttachedPolicies[].PolicyArn --output text

#Create service
cat >keds-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: keda-service-account
  namespace: keda
EOF
kubectl apply -f my-service-account.yaml

account_id=$(aws sts get-caller-identity --query "Account" --output text)
oidc_provider=$(aws eks describe-cluster --name eks-keda-scale --region us-west-1 --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")

export namespace=keda
export service_account=keda-service-account

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
          "$oidc_provider:aud": "sts.amazonaws.com",
          "$oidc_provider:sub": "system:serviceaccount:$namespace:$service_account"
        }
      }
    }
  ]
}
EOF

cat trust-relationship.json                                                               
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::809980971988:oidc-provider/oidc.eks.us-west-1.amazonaws.com/id/16844AFC98C1CE163097C14FE4549806"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-west-1.amazonaws.com/id/16844AFC98C1CE163097C14FE4549806:aud": "sts.amazonaws.com",
                    "oidc.eks.us-west-1.amazonaws.com/id/16844AFC98C1CE163097C14FE4549806:sub": "system:serviceaccount:keda:keda-operator"
                }
            }
        }
    ]
}


aws iam create-role --role-name keda-role --assume-role-policy-document file://trust-relationship1.json --description "keda role-description"

aws iam attach-role-policy --role-name keda-role --policy-arn=arn:aws:iam::809980971988:policy/keda-sqs-policy

aws iam attach-role-policy --role-name keda-role --policy-arn=arn:aws:iam::809980971988:policy/keda-dynamo-policy

kubectl annotate serviceaccount -n keda keda-service-account eks.amazonaws.com/role-arn=arn:aws:iam::$account_id:role/keda-role

aws iam get-role --role-name keda-role  --query Role.AssumeRolePolicyDocument

aws iam list-attached-role-policies --role-name keda-role --output text

export policy_arn=arn:aws:iam::809980971988:policy/keda-sqs-policy 

aws iam get-policy --policy-arn $policy_arn


aws iam get-policy-version --policy-arn $policy_arn --version-id v1

#Configuring pods to use a Kubernetes service account
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