#!/bin/bash

# Script d'arrêt des jobs Laravel AlertContact
# Usage: ./stop_jobs.sh

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/storage/logs"
PID_DIR="$SCRIPT_DIR/storage/app/pids"
UNIFIED_LOG="$LOG_DIR/jobs_unified.log"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$UNIFIED_LOG"
}

print_status() {
    echo -e "${2}$1${NC}"
    log_message "$1"
}

mkdir -p "$LOG_DIR" "$PID_DIR"

print_status "🛑 Arrêt des workers Laravel AlertContact..." "$BLUE"

stop_worker() {
    local worker_name=$1
    local pid_file="$PID_DIR/${worker_name}.pid"

    if [ ! -f "$pid_file" ]; then
        print_status "⚠️  Aucun fichier PID pour $worker_name" "$YELLOW"
        return 0
    fi

    local pid=$(cat "$pid_file")
    if ! kill -0 "$pid" 2>/dev/null; then
        print_status "⚠️  Worker $worker_name (PID: $pid) déjà arrêté" "$YELLOW"
        rm -f "$pid_file"
        return 0
    fi

    print_status "🛑 Arrêt du worker $worker_name (PID: $pid)..." "$YELLOW"
    kill -TERM "$pid" 2>/dev/null

    local count=0
    while kill -0 "$pid" 2>/dev/null && [ $count -lt 30 ]; do
        sleep 1
        count=$((count + 1))
        if [ $((count % 5)) -eq 0 ]; then
            print_status "⏳ Attente de l'arrêt... (${count}s)" "$YELLOW"
        fi
    done

    if kill -0 "$pid" 2>/dev/null; then
        print_status "⚡ Arrêt forcé du worker $worker_name" "$RED"
        kill -KILL "$pid" 2>/dev/null
    fi

    if kill -0 "$pid" 2>/dev/null; then
        print_status "❌ Échec arrêt $worker_name" "$RED"
        return 1
    else
        print_status "✅ $worker_name arrêté" "$GREEN"
        rm -f "$pid_file"
        return 0
    fi
}

stopped=0
failed=0
for pid_file in "$PID_DIR"/*.pid; do
    if [ -f "$pid_file" ]; then
        worker_name=$(basename "$pid_file" .pid)
        if stop_worker "$worker_name"; then
            stopped=$((stopped + 1))
        else
            failed=$((failed + 1))
        fi
    fi
done

print_status "🧹 Nettoyage des processus orphelins artisan queue:work" "$BLUE"
pkill -f "artisan queue:work" 2>/dev/null || true

if [ $failed -eq 0 ]; then
    print_status "✅ Tous les workers arrêtés ($stopped)" "$GREEN"
else
    print_status "⚠️  Workers arrêtés: $stopped, échecs: $failed" "$YELLOW"
fi

log_message "=== Arrêt des jobs terminé ==="