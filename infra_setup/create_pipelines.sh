#!/bin/bash

# filepath: /c:/Users/matth/Documents/mlops-workshop/create_stacks.sh

# Path to the users.json file
# USERS_FILE="users.json"

# # Read the usernames from the JSON file
# USERNAMES=$(jq -r 'keys[]' $USERS_FILE)

USERS=(
  "prod MatthiasMurray"
)

# Iterate through each username and create a CloudFormation stack
for USER in "${USERS[@]}"; do
  # Split the USER variable into uid and githubprofile
  IFS=' ' read -r uid githubprofile <<< "$USER"
  echo "Creating stack for user: $uid with githubprofile: $githubprofile"
  aws cloudformation create-stack \
    --stack-name "codebuild-codepipeline-connection-$uid" \
    --template-body file://user-pipelines.yaml \
    --parameters ParameterKey=uid,ParameterValue=$uid \
                 ParameterKey=githubprofile,ParameterValue=$githubprofile \
    --capabilities CAPABILITY_NAMED_IAM \
    --profile mmur-admin
done