#!/bin/bash
set -e

echo "Starting pipeline execution..."
EXEC_ID=$(harness execute pipeline doom_deploy | grep ExecutionId | awk '{print $2}')
echo "Execution ID: $EXEC_ID"

echo "Waiting for pipeline to complete..."
while true; do
  STATUS=$(harness get execution "$EXEC_ID" --format json | jq -r '.pipelineExecutionSummary.status')
  echo "Current status: $STATUS"
  
  if [ "$STATUS" = "Success" ] || [ "$STATUS" = "Failed" ] || [ "$STATUS" = "Aborted" ]; then
    break
  fi

  # Check for pending approvals
  APP_WAITING=$(harness list approval_instance "$EXEC_ID" --format json | jq -r '.[] | select(.status == "WAITING") | .id' 2>/dev/null || true)
  if [ -n "$APP_WAITING" ]; then
    for ID in $APP_WAITING; do
      echo "Approving instance: $ID"
      harness execute approval_instance:approve "$ID" --force
    done
  fi
  
  sleep 15
done

echo "Done."
