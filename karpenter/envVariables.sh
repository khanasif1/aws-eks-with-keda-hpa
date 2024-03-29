#  Set environment variables

export KARPENTER_VERSION=v0.20.0 # latest: v0.26.1
export CLUSTER_NAME=eks-oregon-scale 
export REGION=us-west-2
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
export AWS_REGION=us-west-2
