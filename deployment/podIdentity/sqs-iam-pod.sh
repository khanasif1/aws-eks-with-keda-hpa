#Create service
cat >keds-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: keda-service-account-pod
  namespace: keda-test
EOF
kubectl apply -f deployment/podIdentity/keds-service-account.yaml
kubectl delete serviceaccount keda-service-account-pod -n keda-test -n keda-test  

account_id=$(aws sts get-caller-identity --query "Account" --output text)
echo $account_id   
kubectl annotate serviceaccount -n keda-test keda-service-account-pod eks.amazonaws.com/role-arn=arn:aws:iam::$account_id:role/keda-role


kubectl annotate --overwrite serviceaccount -n keda-test keda-service-account-pod eks.amazonaws.com/role-arn=arn:aws:iam::809980971988:role/keda-role
#arn:aws:iam::809980971988:role/keda-role