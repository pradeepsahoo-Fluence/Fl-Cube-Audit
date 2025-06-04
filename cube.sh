#!/bin/bash
#This is a simple script to check multiple cube's status by various way, PING, SSH , and telent.

# === Config files and All directories ===
INPUT_FILE="/home/effone.psahoo/cube/host.txt"
OUTPUT_DIR="/home/effone.psahoo/cube/output"
DEBUG_LOG="/home/effone.psahoo/cube/cube_debug.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
FILENAME="device_status_$(date +%Y%m%d%H%M%S).csv"
OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"

# === Make sure output directory exists ===
mkdir -p "$OUTPUT_DIR"

# === Debug log header ===
{
  echo "=== Run at: $TIMESTAMP ==="
  echo "Running as: $(whoami)"
  echo "PATH: $PATH"
  echo "Working dir: $(pwd)"
  echo "Host file exists: $(test -f "$INPUT_FILE" && echo YES || echo NO)"
  echo "Output file: $OUTPUT_FILE"
} >> "$DEBUG_LOG"

# === Fail if host.txt doesn't exist ===
if [ ! -f "$INPUT_FILE" ]; then
  echo "❌ $INPUT_FILE not found. Exiting." >> "$DEBUG_LOG"
  exit 1
fi

# === Write CSV header ===
echo "time,Device name,Ping,SSH,Telnet" > "$OUTPUT_FILE"

# === Read each line from host.txt ===
while IFS=',' read -r NAME HOST PORT; do
  NAME=$(echo "$NAME" | xargs)
  HOST=$(echo "$HOST" | xargs)
  PORT=$(echo "$PORT" | xargs)

  # --- Ping test ---
  /bin/ping -c 1 -W 1 "$HOST" > /dev/null 2>&1
  [ $? -eq 0 ] && PING_STATUS="Reachable" || PING_STATUS="Unreachable"

  # --- SSH (port 22) test ---
  timeout 3 bash -c "echo >/dev/tcp/$HOST/22" 2>/dev/null
  [ $? -eq 0 ] && SSH_STATUS="Reachable" || SSH_STATUS="Unreachable"

  # --- Telnet-style check for target port ---
  timeout 2 bash -c "echo >/dev/tcp/$HOST/$PORT" 2>/dev/null
  [ $? -eq 0 ] && TELNET_STATUS="Reachable" || TELNET_STATUS="Unreachable"

  # --- Append result to output file ---
  echo "$TIMESTAMP,$NAME,$PING_STATUS,$SSH_STATUS,$TELNET_STATUS" >> "$OUTPUT_FILE"

done < "$INPUT_FILE"

echo "✅ Script completed. Output file: $OUTPUT_FILE" >> "$DEBUG_LOG"
