#!/bin/bash
set -e

# === CONFIGURATION ===
TASK_FAMILY="$TASK_FAMILY"  # The ECS task family name
CONTAINER_NAME="$CONTAINER_NAME"  # The name of the container to update
NEW_IMAGE_URI="$IMAGE_URI"  # The new image URI to use
# SECRET_NAME="$SECRET_NAME"  # The name of the secret to update

echo "📥 Fetching latest task definition..."
# Get the current task definition
TASK_DEF_JSON=$(aws ecs describe-task-definition --task-definition "$TASK_FAMILY")
if [ $? -ne 0 ]; then
  echo "❌ Failed to fetch task definition for $TASK_FAMILY"
  exit 1
fi

# Create a new task definition with just the image updated
# Create a new task definition with image updated and fault injection turned off
UPDATED_TASK_DEF=$(echo "$TASK_DEF_JSON" | jq --arg IMAGE "$NEW_IMAGE_URI" --arg NAME "$CONTAINER_NAME" '.taskDefinition | 
  del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy) |
  .containerDefinitions = [.containerDefinitions[] | if .name == $NAME then .image = $IMAGE else . end] |
  .runtimePlatform = {
    "cpuArchitecture": "ARM64",
    "operatingSystemFamily": "LINUX"
  }')

echo "🧱 Registering new task revision..."
# Register the new task definition with the same parameters but the new image
NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --cli-input-json "$UPDATED_TASK_DEF" | jq -r '.taskDefinition.taskDefinitionArn')

# Check if task definition registration was successful
if [ -z "$NEW_TASK_DEF_ARN" ] || [ "$NEW_TASK_DEF_ARN" == "null" ]; then
  echo "❌ Failed to register new task definition"
  exit 1
fi

# echo "🔐 Updating secret in AWS Secrets Manager..."
# aws secretsmanager update-secret \
#   --secret-id "$SECRET_NAME" \
#   --secret-string "{\"ECS_TASK_ARN\":\"$NEW_TASK_DEF_ARN\"}" || {
#     echo "❌ Failed to update secret in AWS Secrets Manager"
#     exit 1
#   }

echo "✅ Registered new task definition:"
echo "$NEW_TASK_DEF_ARN"