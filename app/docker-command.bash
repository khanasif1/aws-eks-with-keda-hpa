#Build the image

docker build -t sqs-reader .
docker login
docker tag sqs-reader:latest khanasif1/sqs-reader:v0.1
docker push khanasif1/sqs-reader:v0.1  
