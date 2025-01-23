import boto3
import json
import time
import webbrowser

# Initialize boto3 clients
sts_client = boto3.client('sts')
iam_client = boto3.client('iam')
secrets_client = boto3.client('secretsmanager')
codestar_connections_client = boto3.client('codestar-connections')
codebuild_client = boto3.client('codebuild')
codepipeline_client = boto3.client('codepipeline')

# Get the IAM username
iam_username = sts_client.get_caller_identity()['Arn'].split('/')[-1]

# Variables
codebuild_project_name = f"{iam_username}-codebuild-project"
codepipeline_name = f"{iam_username}-codepipeline"
github_connection_name = f"{iam_username}-connection"
github_profile_name = json.loads(secrets_client.get_secret_value(SecretId=f'{iam_username}-github-profile-name')['SecretString'])['Value']
github_repo = f"{github_profile_name}/mlops-workshop"
github_branch = "main"  # Replace with your desired branch name
account_id = sts_client.get_caller_identity()['Account']

codebuild_role_name = f"{iam_username}-codebuild-service-role"
codepipeline_role_name = f"{iam_username}-codepipeline-service-role"

# Create GitHub connection
# github_connection_response = codestar_connections_client.create_connection(
#     providerType='GitHub',
#     connectionName=github_connection_name
# )
# github_connection_arn = github_connection_response['ConnectionArn']

# # Extract the region from the connection ARN
# aws_region = github_connection_arn.split(':')[3]

# # Trigger browser approval for GitHub connection
# approval_url = f"https://{aws_region}.console.aws.amazon.com/codesuite/settings/connections/{github_connection_arn}"
# print(f"Please approve the GitHub connection in your browser: {approval_url}")
# webbrowser.open(approval_url)

# # Wait for user to approve the connection
# input("Press [Enter] once you have approved the connection...")

# # Create CodeBuild project
# codebuild_client.create_project(
#     name=codebuild_project_name,
#     source={
#         'type': 'CODEPIPELINE',
#         'buildSpec': 'buildspec.yml',
#         'insecureSsl': False
#     },
#     artifacts={
#         'type': 'CODEPIPELINE',
#         'name': codebuild_project_name,
#         'packaging': 'NONE',
#         'encryptionDisabled': False
#     },
#     cache={
#         'type': 'NO_CACHE'
#     },
#     environment={
#         'type': 'LINUX_CONTAINER',
#         'image': 'aws/codebuild/amazonlinux-x86_64-standard:5.0',
#         'computeType': 'BUILD_GENERAL1_SMALL',
#         'environmentVariables': [],
#         'privilegedMode': False,
#         'imagePullCredentialsType': 'CODEBUILD'
#     },
#     serviceRole=f"arn:aws:iam::{account_id}:role/{codebuild_role_name}",
#     timeoutInMinutes=60,
#     queuedTimeoutInMinutes=480,
#     encryptionKey=f"arn:aws:kms:{aws_region}:{account_id}:alias/aws/s3",
#     tags=[],
#     logsConfig={
#         'cloudWatchLogs': {
#             'status': 'ENABLED'
#         },
#         's3Logs': {
#             'status': 'DISABLED'
#         }
#     }
# )

# # Create pipeline.json content
# pipeline_json = {
#     "pipeline": {
#         "name": codepipeline_name,
#         "roleArn": f"arn:aws:iam::{account_id}:role/{codepipeline_role_name}",
#         "artifactStore": {
#             "type": "S3",
#             "location": f"codepipeline-{aws_region}-222613562898",
#         },
#         "stages": [
#             {
#                 "name": "Source",
#                 "actions": [
#                     {
#                         "name": "Source",
#                         "actionTypeId": {
#                             "category": "Source",
#                             "owner": "AWS",
#                             "provider": "CodeStarSourceConnection",
#                             "version": "1"
#                         },
#                         "runOrder": 1,
#                         "configuration": {
#                             "ConnectionArn": github_connection_arn,
#                             "DetectChanges": "false",
#                             "FullRepositoryId": github_repo,
#                             "BranchName": github_branch,
#                             "OutputArtifactFormat": "CODE_ZIP"
#                         },
#                         "outputArtifacts": [
#                             {
#                                 "name": "SourceArtifact"
#                             }
#                         ]
#                     }
#                 ]
#             },
#             {
#                 "name": "Build",
#                 "actions": [
#                     {
#                         "name": "Build",
#                         "actionTypeId": {
#                             "category": "Build",
#                             "owner": "AWS",
#                             "provider": "CodeBuild",
#                             "version": "1"
#                         },
#                         "runOrder": 1,
#                         "configuration": {
#                             "ProjectName": codebuild_project_name
#                         },
#                         "inputArtifacts": [
#                             {
#                                 "name": "SourceArtifact"
#                             }
#                         ],
#                         "outputArtifacts": [
#                             {
#                                 "name": "BuildArtifact"
#                             }
#                         ]
#                     }
#                 ]
#             }
#         ],
#         "executionMode": "QUEUED",
#         "pipelineType": "V2",
#         "triggers": [
#             {
#                 "providerType": "CodeStarSourceConnection",
#                 "gitConfiguration": {
#                     "sourceActionName": "Source",
#                     "push": [
#                         {
#                             "branches": {
#                                 "includes": [
#                                     "main"
#                                 ]
#                             }
#                         }
#                     ]
#                 }
#             }
#         ]
#     }
# }

# # Create the CodePipeline
# codepipeline_client.create_pipeline(pipeline=pipeline_json)

# print(f"CodePipeline {codepipeline_name} created successfully.")