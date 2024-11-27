#!/bin/bash

usage() {
    echo "Usage: $0 --repo <repository> --token <token> [-h]"
    echo "  --repo                      The url to the repo to register the runner too"
    echo "  --token                     The generated token for the runner"
    echo "  --runner-name               The name of the generated runner"
    echo "  --labels                    The labels of the generated runner"
    echo "  --ecs-task                  Is this runner is an ecs task"
    echo "  -h, --help                  Display this help message"
    exit 1
}

declare -A ARGS=( ["repo"]="REPO" ["token"]="TOKEN" ["runner-name"]="RUNNER_NAME" ["labels"]="LABELS" ["ecs-task"]="ECS_TASK")
REPO="" TOKEN="" RUNNER_NAME="" LABELS="" ECS_TASK=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        --*) 
            key=${1#--}  # Remove '--' prefix
            if [[ -n ${ARGS[$key]} ]]; then
                declare ${ARGS[$key]}="$2"
                shift 2
            else
                echo "Unknown option: $1"
                usage
            fi
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

for arg in "REPO" "TOKEN" "RUNNER_NAME"; do
    if [[ -z "${!arg}" ]]; then
        echo "Error: --${arg,,} is required."  # Convert to lowercase
        usage
    fi
done


if [[ -n "${MY_ENV_VAR}" ]]; then
    TASK_METADATA=$(curl $ECS_CONTAINER_METADATA_URI_V4/task)
    TASK_ID=$(echo $TASK_METADATA | jq -r '.TaskARN' | awk -F'/' '{print $2}')
    RUNNER_NAME+="-$TASK_ID"
fi

echo "Repo: $REPO"

# Fetch runner token
RUNNER_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $TOKEN" \
  "https://api.github.com/repos/$REPO/actions/runners/registration-token" | jq -r '.token')

if [[ -z "$RUNNER_TOKEN" ]]; then
    echo "Error: Failed to fetch runner token."
    exit 1
fi

cd actions-runner || { echo "Error: Directory 'actions-runner' not found."; exit 1; }
./config.sh --unattended --replace --url "https://github.com/$REPO" --token "$RUNNER_TOKEN" --name "$RUNNER_NAME" ${LABELS:+--labels "$LABELS"}
./run.sh
