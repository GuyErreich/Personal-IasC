echo "Supervisor - starting..."

RUNNER_MANAGER_SCRIPT="$RUNNER_MANAGER_DIR/runner_manager.conf"

# Make the runner_manager.sh script executable
chmod +x "$RUNNER_MANAGER_SCRIPT"

sudo cp $RUNNER_MANAGER_SCRIPT /etc/supervisor/conf.d/
sudo supervisord -c /etc/supervisor/conf.d/runner_manager.conf

if [[ $? -eq 0 ]]; then
    echo "Supervisor - started successfully"
else
    echo "Supervisor - ERROR: Supervisor failed"
fi