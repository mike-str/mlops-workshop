#!/bin/bash

# Get the IAM username
IAM_USERNAME=$(aws sts get-caller-identity --query Arn --output text | cut -d '/' -f 2)

# Variables
CODEBUILD_PROJECT_NAME="${IAM_USERNAME}-codebuild-project"
CODEPIPELINE_NAME="${IAM_USERNAME}-codepipeline"
GITHUB_CONNECTION_NAME="${IAM_USERNAME}-connection"
GITHUB_REPO="mlops-workshop"
GITHUB_BRANCH="main"  # Replace with your desired branch name

# Create GitHub connection
GITHUB_CONNECTION_ARN=$(aws codestar-connections create-connection --provider-type GitHub --connection-name $GITHUB_CONNECTION_NAME --query 'ConnectionArn' --output text)

# Trigger browser approval for GitHub connection
aws codestar-connections create-connection --provider-type GitHub --connection-name $GITHUB_CONNECTION_NAME

echo "Please approve the GitHub connection in your browser: https://console.aws.amazon.com/codesuite/settings/connections"

# Wait for user to approve the connection
read -p "Press [Enter] once you have approved the connection..."

# Create CodeBuild project
aws codebuild create-project --name $CODEBUILD_PROJECT_NAME \
  --source type=CODEPIPELINE \
  --artifacts type=CODEPIPELINE \
  --environment type=LINUX_CONTAINER,image=aws/codebuild/standard:5.0,computeType=BUILD_GENERAL1_SMALL \
  --service-role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/service-role/${IAM_USERNAME}-codebuild-role

# Create pipeline.json content
cat <<EOL > pipeline.json
{
  "pipeline": {
    "name": "$CODEPIPELINE_NAME",
    "roleArn": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/service-role/${IAM_USERNAME}-codepipeline-role",
    "artifactStore": {
      "type": "S3",
      "location": "$S3_CODEPIPELINE_BUCKET"  # Replace with your S3 bucket name
    },
    "stages": [
      {
        "name": "Source",
        "actions": [
          {
            "name": "Source",
            "actionTypeId": {
              "category": "Source",
              "owner": "AWS",
              "provider": "CodeStarSourceConnection",
              "version": "1"
            },
            "runOrder": 1,
            "configuration": {
              "ConnectionArn": "$GITHUB_CONNECTION_ARN",
              "FullRepositoryId": "$(aws sts get-caller-identity --query Arn --output text | cut -d '/' -f 2)/$GITHUB_REPO",
              "BranchName": "main",
            },
            "outputArtifacts": [
              {
                "name": "SourceArtifact"
              }
            ]
          }
        ]
      },
      {
        "name": "Build",
        "actions": [
          {
            "name": "Build",
            "actionTypeId": {
              "category": "Build",
              "owner": "AWS",
              "provider": "CodeBuild",
              "version": "1"
            },
            "runOrder": 1,
            "configuration": {
              "ProjectName": "$CODEBUILD_PROJECT_NAME"
            },
            "inputArtifacts": [
              {
                "name": "SourceArtifact"
              }
            ],
            "outputArtifacts": [
              {
                "name": "BuildArtifact"
              }
            ]
          }
        ]
      }
    ]
  }
}
EOL

# Create the pipeline
aws codepipeline create-pipeline --cli-input-json file://pipeline.json

echo "CodeBuild project and CodePipeline have been created successfully."