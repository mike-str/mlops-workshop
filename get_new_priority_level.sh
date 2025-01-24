#!/bin/bash

# filepath: /c:/Users/matth/Documents/mlops-workshop/get_new_priority_level.sh

# Load balancer name
LOAD_BALANCER_NAME="mlops-workshop-alb"

# Get the ARN of the load balancer
ALB_ARN=$(aws elbv2 describe-load-balancers --names $LOAD_BALANCER_NAME --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Get the list of listeners for the load balancer
LISTENERS=$(aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --query 'Listeners[*].ListenerArn' --output text)

# Initialize the maximum priority variable
MAX_PRIORITY=0

# Iterate through each listener to find the maximum priority of rules
for LISTENER_ARN in $LISTENERS; do
  RULES=$(aws elbv2 describe-rules --listener-arn $LISTENER_ARN --query 'Rules[*].Priority' --output text)
  for PRIORITY in $RULES; do
    if [ "$PRIORITY" != "default" ] && [ "$PRIORITY" -gt "$MAX_PRIORITY" ]; then
      MAX_PRIORITY=$PRIORITY
    fi
  done
done

# Return the maximum priority plus 10
echo $((MAX_PRIORITY + 10))