#!/usr/bin/env bash
# Check each cube's status (PING, SSH, and Telnet-style TCP check)
# Uses paths relative to the script’s own directory – no hard-coded absolute paths.

set -euo pipefail

# === Determine the script’s directory ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Config files and directories ===
INPUT_FILE="${SCRIPT_DIR}/host.txt"
OUTPUT_DIR="${SCRIPT_DIR}/output"
DEBUG_LOG="${SCRIPT_DIR}/cube_debug.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"
FILENAME="device_status_$(date +%Y%m%d%H%M%S).csv"
OUTPUT_FILE="${OUTPUT_DIR}/${FILENAME}"

# === Make sure output directory exists ===
mkdir -p "${OUTPUT_DIR}"

# === Debug log header ===
{
  echo "=== Run at: ${TIMESTAMP} ==="
  echo "Running as: $(whoami)"
  echo "PATH: ${PATH}"
  echo "Working dir when invoked: $(pwd)"
  echo "Script directory: ${SCRIPT_DIR}"
  echo "Host file exists: $(test -f "${INPUT_FILE}" && echo YES || echo NO)"
  echo "Output file: ${OUTPUT_FILE}"
} >> "${DEBUG_LOG}"

# === Fail if host.txt doesn't exist ===
if [[ ! -f "${INPUT_FILE}" ]]; then
  echo "❌ ${INPUT_FILE} not found. Exiting." | tee -a "${DEBUG_LOG}"
  exit 1
fi

# === Write CSV header ===
echo "time,Device name,Ping,SSH,Telnet" > "${OUTPUT_FILE}"

# === Read each line from host.txt ===
while IFS=',' read -r NAME HOST PORT || [[ -n "${NAME}${HOST}${PORT}" ]]; do
  # Trim whitespace
  NAME="$(echo "${NAME}" | xargs)"
  HOST="$(echo "${HOST}" | xargs)"
  PORT="$(echo "${PORT}" | xargs)"

  # --- Ping test ---
  if /bin/ping -c 1 -W 1 "${HOST}" > /dev/null 2>&1; then
    PING_STATUS="Reachable"
  else
    PING_STATUS="Unreachable"
  fi

  # --- SSH (port 22) test ---
  if timeout 3 bash -c "echo >/dev/tcp/${HOST}/22" 2>/dev/null; then
    SSH_STATUS="Reachable"
  else
    SSH_STATUS="Unreachable"
  fi

  # --- Telnet-style check for target port ---
  if timeout 2 bash -c "echo >/dev/tcp/${HOST}/${PORT}" 2>/dev/null; then
    TELNET_STATUS="Reachable"
  else
    TELNET_STATUS="Unreachable"
  fi

  # --- Append result to output file ---
  echo "${TIMESTAMP},${NAME},${PING_STATUS},${SSH_STATUS},${TELNET_STATUS}" >> "${OUTPUT_FILE}"
done < "${INPUT_FILE}"

echo "✅ Script completed. Results written to: ${OUTPUT_FILE}" | tee -a "${DEBUG_LOG}"
