helm install keda kedacore/keda --values values.yaml --namespace keda

#helm uninstall keda -n keda        

#Validate
kubectl get pods -n keda | grep keda


kubectl get pods -n keda | grep keda-operator-5d9d4d7964-lvjnk 

kubectl describe pod keda-operator-5d9d4d7964-lvjnk  -n keda| grep AWS_ROLE_ARN:
kubectl describe pod keda-operator-metrics-apiserver-76cd79b8c6-k4g92 -n keda| grep AWS_ROLE_ARN:

kubectl describe pod keda-operator-5d9d4d7964-lvjnk -n keda | grep AWS_WEB_IDENTITY_TOKEN_FILE:

kubectl get deploy -n keda 

kubectl describe deployment keda-operator -n keda | grep "Service Account"

kubectl describe deployment keda-operator-metrics-apiserver  -n keda | grep "Service Account"


#******Deploy Nginx dummy app******

kubectl create deployment nginx-deployment --image nginx -n keda-test
# kubectl delete deployment nginx-deployment  -n keda-test 

#******KEDA SCALE OBJECT & TRIGGER DEPLOYMENT******
kubectl apply -f keda-configure/keda-scaleobject.yaml

#kubectl delete scaledobject aws-sqs-queue-scaledobject -n keda-test 
#kubectl delete triggerauth keda-aws-credentials -n keda-test 

#******KEDA -Deploy python app - it reads the SQS  and put message in dynamo******

kubectl apply -f deployment/keda-python-app.yaml
#kubectl delete deployment sqs-app  -n keda-test    

k get pods -n keda-test  
kubectl describe -p sqs-app-76d4d957b6-674tq   -n keda-test| grep AWS_ROLE_ARN:  
k logs pod sqs-app-76d4d957b6-674tq -n keda-test 


kubectt logt -f sqs-app-597c4bf64d-d5d4t -n keda-test 

#******KARPENTER -Deploy python app - it reads the SQS  and put message in dynamo******
kubectl apply -f deployment/karpenter-python-app.yaml
#kubectl delete deployment sqs-app  -n karpenter-test  
