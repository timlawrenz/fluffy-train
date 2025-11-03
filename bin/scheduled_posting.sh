#!/bin/bash

# Fluffy Train - Scheduled Posting Script
# This script ensures the correct Ruby version is used via RVM

# Exit on error
set -e

# Application directory
APP_DIR="/home/tim/source/activity/fluffy-train"

# Log file
LOG_FILE="/home/tim/source/activity/fluffy-train/log/scheduled_posting.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Starting scheduled post check"

# Load RVM into shell session
if [ -s "$HOME/.rvm/scripts/rvm" ]; then
    source "$HOME/.rvm/scripts/rvm"
elif [ -s "/usr/share/rvm/scripts/rvm" ]; then
    source "/usr/share/rvm/scripts/rvm"
else
    log "ERROR: RVM not found"
    exit 1
fi

# Change to application directory
cd "$APP_DIR" || {
    log "ERROR: Cannot change to $APP_DIR"
    exit 1
}

# Use the correct Ruby version (will read from .ruby-version or Gemfile)
rvm use 3.4.5 2>&1 | tee -a "$LOG_FILE"

# Verify Ruby version
RUBY_VERSION=$(ruby -v)
log "Using Ruby: $RUBY_VERSION"

# Run the scheduled posting task
log "Running scheduled post task..."
bundle exec rails scheduling:post_scheduled 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
    log "Completed successfully"
else
    log "ERROR: Task exited with code $EXIT_CODE"
fi

log "=========================================="

exit $EXIT_CODE
