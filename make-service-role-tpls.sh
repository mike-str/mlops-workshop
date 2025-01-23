#!/bin/bash

PROFILE="mmur-admin"
ROLE_NAMES=("mlops-workshop-dev-codebuild-project-service-role" "mlops-workshop-dev-codepipeline-service-role")

for ROLE_NAME in "${ROLE_NAMES[@]}"; do
  # Get the role details
  ROLE_DETAILS=$(aws iam get-role --role-name "$ROLE_NAME" --profile "$PROFILE")
  TRUST_POLICY=$(echo "$ROLE_DETAILS" | jq '.Role.AssumeRolePolicyDocument')

  # List attached managed policies
  ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --profile "$PROFILE" --query 'AttachedPolicies[*].PolicyArn' --output json)

  # Get inline policies
  INLINE_POLICIES=$(aws iam list-role-policies --role-name "$ROLE_NAME" --profile "$PROFILE" --query 'PolicyNames' --output json)

  # Initialize JSON object
  ROLE_JSON=$(jq -n --argjson trustPolicy "$TRUST_POLICY" --argjson attachedPolicies "$ATTACHED_POLICIES" --argjson inlinePolicies "$INLINE_POLICIES" '{
    TrustPolicy: $trustPolicy,
    AttachedPolicies: $attachedPolicies,
    InlinePolicies: $inlinePolicies
  }')

  # Get details of each attached managed policy
  for POLICY_ARN in $(echo "$ATTACHED_POLICIES" | jq -r '.[]'); do
    POLICY_DETAILS=$(aws iam get-policy --policy-arn "$POLICY_ARN" --profile "$PROFILE")
    VERSION_ID=$(echo "$POLICY_DETAILS" | jq -r '.Policy.DefaultVersionId')
    POLICY_VERSION=$(aws iam get-policy-version --policy-arn "$POLICY_ARN" --version-id "$VERSION_ID" --profile "$PROFILE" --query 'PolicyVersion.Document' --output json)
    ROLE_JSON=$(echo "$ROLE_JSON" | jq --arg policyArn "$POLICY_ARN" --argjson policyVersion "$POLICY_VERSION" '.AttachedPolicies += [{($policyArn): $policyVersion}]')
  done

  # Get details of each inline policy
  for POLICY_NAME in $(echo "$INLINE_POLICIES" | jq -r '.[]'); do
    INLINE_POLICY=$(aws iam get-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" --profile "$PROFILE" --query 'PolicyDocument' --output json)
    ROLE_JSON=$(echo "$ROLE_JSON" | jq --arg policyName "$POLICY_NAME" --argjson policyDocument "$INLINE_POLICY" '.InlinePolicies += [{($policyName): $policyDocument}]')
  done

  # Replace 'mlops-workshop-dev' with '${aws:username}'
  ROLE_JSON=$(echo "$ROLE_JSON" | sed 's/mlops-workshop-dev/${aws:username}/g')

  # Save to file
  echo "$ROLE_JSON" > "${ROLE_NAME}.json"
done