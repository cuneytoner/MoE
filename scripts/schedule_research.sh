#!/bin/bash

# ==============================================================================
# Script Name:  schedule_research.sh
# Description:  Network orchestration pipeline executing on PC-1 to push and
#               inject systemic cron patterns onto the PC-2 worker node.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "[CRITICAL ERROR] Configuration manifest (.env) missing."
    exit 1
fi

source "$ENV_FILE"

# Extract the primary remote worker target node IP
PRIMARY_WORKER=$(echo "$REMOTE_NODES" | awk '{print $1}')

echo "========================================================================"
echo "[ORCHESTRATOR CLUSTER] Injecting Cron Timelines onto Node: ${PRIMARY_WORKER}"
echo "========================================================================"

# Define the production cron schedule string targeting PC-2 local paths
# Trigger cycle: Every night at exactly 02:00 AM (0 2 * * *)
CRON_JOB="0 2 * * * /home/${DEPLOY_USER}/MoE/scripts/run_research.sh > /home/${DEPLOY_USER}/MoE/research_nightly.log 2>&1"

# Remotely check and inject the cron mapping over keyless SSH pipe
ssh "${DEPLOY_USER}@${PRIMARY_WORKER}" "
    (crontab -l 2>/dev/null | grep -v 'run_research.sh'; echo '${CRON_JOB}') | crontab -
    echo '[SUCCESS] Remote crontab updated successfully. Schedule active at 02:00 AM.'
"
