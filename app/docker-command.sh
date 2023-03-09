#Build the image

docker buildx build -t sqs-reader --platform=linux/amd64 .
docker login
docker tag sqs-reader:latest khanasif1/sqs-reader:v0.1
docker push khanasif1/sqs-reader:v0.1  
