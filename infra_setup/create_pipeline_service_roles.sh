#!/bin/bash

# filepath: /c:/Users/matth/Documents/mlops-workshop/create_stacks.sh

# Path to the users.json file
# USERS_FILE="users.json"

# # Read the usernames from the JSON file
# USERNAMES=$(jq -r 'keys[]' $USERS_FILE)

USERNAMES=("prod")

# Iterate through each username and create a CloudFormation stack
for USERNAME in $USERNAMES; do
  echo "Creating stack for user: $USERNAME"
  aws cloudformation deploy \
    --stack-name "codebuild-codepipeline-service-roles-$USERNAME" \
    --template-file codebuild-service-role.yaml \
    --parameter-overrides uid=$USERNAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile mmur-admin
done