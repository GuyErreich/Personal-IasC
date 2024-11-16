#!/bin/bash

usage() {
    echo "Usage: $0 --repo <repository> --token <token> [-h]"
    echo "  --repo                      The url to the repo to register the runner too"
    echo "  --token                     The generated token for the runner"
    echo "  --runner-name               The name of the generated runner"
    # echo "  --aws-region                The region the ecr exist on"
    # echo "  --aws-secret-access-key     The secret accsses key to connect to the aws region ecr"
    # echo "  --aws-access-key-id         The access key id"
    echo "  -h, --help                  Display this help message"
    exit 1
}

REPO=""
TOKEN=""
RUNNER_NAME=""
# REGION=""
# AWS_SECRET_ACCESS_KEY=""
# AWS_ACCESS_KEY_ID=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --repo)
        REPO="$2"
        shift 2
        ;;
        --token)
        TOKEN="$2"
        shift 2
        ;;
        --runner-name)
        RUNNER_NAME="$2"
        shift 2
        ;;
        # --aws-region)
        # REGION="$2"
        # shift 2
        # ;;
        # --aws-secret-access-key)
        # AWS_SECRET_ACCESS_KEY="$2"
        # shift 2
        # ;;
        # --aws-access-key-id)
        # AWS_ACCESS_KEY_ID="$2"
        # shift 2
        # ;;
        --help)
        usage
        ;;
        *)
        echo "Unknown option: $1"
        usage
        ;;
    esac
done

# Check required parameters
if [[ -z "$REPO" ]]; then
  echo "Error: --repo is required."
  usage
fi

if [[ -z "$TOKEN" ]]; then
  echo "Error: --token is required."
  usage
fi

if [[ -z "$RUNNER_NAME" ]]; then
  echo "Error: --runner-name is required."
  usage
fi

# if [[ -z "$REGION" ]]; then
#   echo "Error: --aws-region is required."
#   usage
# fi

# if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
#   echo "Error: --aws-secret-access-key is required."
#   usage
# fi

# if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
#   echo "Error: --aws-access-key-id is required."
#   usage
# fi

# ECR="961341519925.dkr.ecr.$REGION.amazonaws.com"

# $(aws ecr get-login-password --region $REGION | \
# docker login --username AWS --password-stdin $ECR)

echo "Repo: $REPO"

RUNNER_TOKEN=$(curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  https://api.github.com/repos/$REPO/actions/runners/registration-token | jq -r '.token')

echo $RUNNER_TOKEN

cd actions-runner
./config.sh --unattended --replace --url https://github.com/$REPO --token $RUNNER_TOKEN --name $RUNNER_NAME
./run.sh
