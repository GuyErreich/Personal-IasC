#!/bin/bash

TIMESTAMP_FILE="/tmp/last_active_timestamp"
CHECK_INTERVAL=1  # Check every 60 seconds
GRACE_PERIOD=20

# Function to fetch runner ID
get_runner_id() {
    local runner_id

    runner_id=$(curl -s \
        -H "Authorization: Bearer $TOKEN" \
        "https://api.github.com/repos/$REPO/actions/runners" | jq -r ".runners[] | select(.name == \"$RUNNER_NAME\") | .id")

    if [[ -z "$runner_id" ]]; then
        echo "Error: Unable to fetch runner ID for $RUNNER_NAME."
        exit 1
    fi

    echo "$runner_id"
}

# Function to fetch active jobs for the runner
fetch_runner_status() {
    local runner_id=$(get_runner_id)

    local runner_status=$(curl -s \
        -H "Authorization: Bearer $TOKEN" \
        "https://api.github.com/repos/$REPO/actions/runners/$runner_id" | jq '.busy')

    echo "$runner_status"
}

# Function to cleanup the runner
cleanup_runner() {
    echo "Checking if the runner can be deregistered..."

    local runner_status=$(fetch_runner_status)
    if [[ "$runner_status" == "false" ]]; then
        echo "No active jobs. Deregistering the runner..."

        local runner_id=$(get_runner_id)
        if [[ -n "$runner_id" ]]; then
            # Delete the runner
            # RESPONSE=$(curl -s -X DELETE \
            #     -H "Authorization: Bearer $TOKEN" \
            #     "https://api.github.com/repos/$REPO/actions/runners/$runner_id")

            \../actions-runner/config.sh remove --token $RUNNER_TOKEN

            if [[ $? -eq 0 ]]; then
                echo "Runner $RUNNER_NAME deregistered successfully."
            else
                echo "Error: Failed to deregister the runner."
            fi
        else
            echo "Warning: Could not find runner ID for $RUNNER_NAME. Skipping deregistration."
        fi
    else
        echo "Active jobs still running ($runner_status). Skipping deregistration."
    fi
}

update_last_active_timestamp() {
    echo "$(date +%s)" > "$TIMESTAMP_FILE"
}

get_last_active_timestamp() {
    if [[ -f "$TIMESTAMP_FILE" ]]; then
        cat "$TIMESTAMP_FILE"
    else
        echo "0"  # Default to epoch if no timestamp exists
    fi
}

run_manager() {
    while true; do
        echo "Checking runner status..."

        local runner_status=$(fetch_runner_status)
        echo "runner_status: $runner_status"
        if [[ "$runner_status" == "true" ]]; then
            echo "Jobs still active status - busy: ($runner_status). Updating last active timestamp."
            update_last_active_timestamp
        else
            echo "Jobs still active status - busy: ($runner_status)."
            local current_time=$(date +%s)
            local last_active=$(get_last_active_timestamp)
            local idle_time=$((current_time - last_active))

            echo "Runner idle for $idle_time seconds (grace period: $GRACE_PERIOD seconds)."

            if [[ "$idle_time" -ge "$GRACE_PERIOD" ]]; then
                echo "Grace period exceeded. Initiating cleanup..."
                cleanup_runner
                echo "Exiting the script after cleanup."
                exit 0
            else
                echo "Runner is within the grace period. Skipping cleanup."
            fi
        fi

        echo "Sleeping for $CHECK_INTERVAL seconds..."
        sleep "$CHECK_INTERVAL"
    done
}

update_last_active_timestamp

run_manager
