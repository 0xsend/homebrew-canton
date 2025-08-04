#!/bin/bash
set -euo pipefail

# Simple Canton Homebrew Formula Update Script
# Uses local TypeScript scripts to update Canton formula and create releases

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly LOG_FILE="${SCRIPT_DIR}/log/update.log"
readonly ERROR_LOG="${SCRIPT_DIR}/log/update-errors.log"

# Ensure log directory exists
mkdir -p "${SCRIPT_DIR}/log"

# Logging functions
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $*" | tee -a "${LOG_FILE}"
}

error() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[ERROR ${timestamp}] $*" | tee -a "${ERROR_LOG}" >&2
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v bun >&/dev/null; then
        error "Bun is not installed or not in PATH"
        return 1
    fi
    
    if [ ! -f "${SCRIPT_DIR}/scripts/update-homebrew-formula.ts" ]; then
        error "TypeScript update script not found at ${SCRIPT_DIR}/scripts/update-homebrew-formula.ts"
        return 1
    fi
    
    if [ ! -f "${SCRIPT_DIR}/Formula/canton.rb" ]; then
        error "Canton formula not found at ${SCRIPT_DIR}/Formula/canton.rb"
        return 1
    fi
    
    log "Prerequisites check passed"
    return 0
}

# Main update function
run_update() {
    log "=== Starting Canton Homebrew Formula Update ==="
    
    # Change to script directory for consistent paths
    cd "${SCRIPT_DIR}"
    
    log "Running TypeScript update script..."
    if bun run scripts/update-homebrew-formula.ts; then
        log "TypeScript update script completed successfully"
        return 0
    else
        error "TypeScript update script failed with exit code $?"
        return 1
    fi
}

# Cleanup function for graceful shutdown
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        error "Script failed with exit code ${exit_code}"
    else
        log "Script completed successfully"
    fi
    log "=== Update process finished ==="
}

# Set up cleanup trap
trap cleanup EXIT

# Main execution
main() {
    log "Starting update process from directory: ${SCRIPT_DIR}"
    
    if ! check_prerequisites; then
        error "Prerequisites check failed"
        exit 1
    fi
    
    if ! run_update; then
        error "Update process failed"
        exit 1
    fi
    
    log "Canton formula update completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi