user=$1
service=$2

# vars
SERVICE_NAME=$user-$service
VENV_NAME="$SERVICE_NAME-venv"
export $(cat vars.txt | xargs)

# create venv
python3 -m venv $VENV_NAME
source $VENV_NAME/bin/activate
pip install --no-cache-dir -r requirements.txt

# setup build assets
source setup.sh

# run build on assets
source build.sh

# # login to ecr
# aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# # build docker image
# docker build \
#     --build-arg SERVICE_NAME=$SERVICE_NAME \
#     -t $SERVICE_NAME .

# # check if ecr repo exists, if not create it
# REPO_EXISTS=$(aws ecr describe-repositories --repository-names $SERVICE_NAME --query 'repositories[0].repositoryName' --output text)
# if [ "$REPO_EXISTS" == "$SERVICE_NAME" ]; then
#     echo "ECR repo exists."
# else
#     echo "ECR repo does not yet exist. Creating ECR repo..."
#     aws ecr create-repository --repository-name $SERVICE_NAME
# fi

# # tag and push docker image to ecr
# docker tag $SERVICE_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE_NAME:latest
# docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE_NAME:latest

# # create ecs task definition
# sed -e "s;%AWS_ACCOUNT_ID%;$AWS_ACCOUNT_ID;g" \
#     -e "s;%AWS_REGION%;$AWS_REGION;g" \
#     -e "s;%SERVICE_NAME%;$SERVICE_NAME;g" \
#     -e "s;%VENV_NAME%;$VENV_NAME;g" \
#     -e "s;%USER%;$user;g" \
#     ecs-task-def.json > ecs-task-def-$SERVICE_NAME.json

# # register task definition
# aws ecs register-task-definition --cli-input-json file://ecs-task-def-$SERVICE_NAME.json

# # check if cloudwatch log group exists, if not create it
# LOG_GROUP_EXISTS=$(aws logs describe-log-groups --log-group-name-prefix /ecs/$SERVICE_NAME --query 'logGroups[0].logGroupName' --output text)
# if [ "$LOG_GROUP_EXISTS" == "/ecs/$SERVICE_NAME" ]; then
#     echo "Cloudwatch log group exists."
# else
#     echo "Cloudwatch log group does not yet exist. Creating Cloudwatch log group..."
#     aws logs create-log-group --log-group-name /ecs/$SERVICE_NAME
# fi

# # Get priority of existing service or next available priority
# PRIORITY=$(( $(aws ecs describe-services --cluster mlops-workshop-cluster --services existing-service-name --query "services[0].priority" --output text 2>/dev/null || echo 0) + 10 ))

# # check if ecs service exists, if not create it, else update it
# SERVICE_EXISTS=$(aws ecs describe-services --cluster mlops-workshop-cluster --services $SERVICE_NAME --query 'services[0].serviceName' --output text)
# if [ "$SERVICE_EXISTS" == "ACTIVE" ]; then
#     echo "Service exists. Updating the service..."
#     aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment
# else
#     echo "Service does not yet exist. Creating ECS service..."
#     echo "Setting up ALB routing for $SERVICE_NAME..."
#     export ALB_ARN=$(aws elbv2 describe-load-balancers --names mlops-workshop-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
#     export TG_ARN=$(aws elbv2 create-target-group --name $SERVICE_NAME-tg --protocol HTTP --port 80 --vpc-id $VPC_ID --target-type ip --health-check-path "/${SERVICE_NAME}/health" --query 'TargetGroups[0].TargetGroupArn' --output text)
#     echo "Adding routing rule for /$SERVICE_NAME..."
#     export LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query 'Listeners[0].ListenerArn' --output text)
#     aws elbv2 create-rule --listener-arn $LISTENER_ARN --conditions '[{"Field":"path-pattern","Values":["/'"$SERVICE_NAME"'/*"]}]' --priority $PRIORITY --actions '[{"Type":"forward","TargetGroupArn":"'"$TG_ARN"'"}]'
#     echo "Creating ECS service..."
#     aws ecs create-service \
#         --cluster $CLUSTER_NAME \
#         --service-name $SERVICE_NAME \
#         --task-definition $SERVICE_NAME \
#         --desired-count 1 \
#         --launch-type FARGATE \
#         --network-configuration "awsvpcConfiguration={subnets=[subnet-061a6219b4c4f846a,subnet-0e4dcb4f98967aaec],securityGroups=[sg-09e220f656a51ebb9],assignPublicIp=ENABLED}" \
#         --load-balancers "targetGroupArn=$TG_ARN,containerName=$SERVICE_NAME,containerPort=80"
# fi

# save python dependencies
pip freeze > requirements-updated.txt