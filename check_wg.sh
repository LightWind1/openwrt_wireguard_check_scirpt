#!/bin/bash
# 用法: check_wg.sh <接口名> <最大无握手秒数>
# 示例: check_wg.sh wg0 300

WG_IFACE=$1
MAX_IDLE=$2

# 参数检查
if [[ -z "$WG_IFACE" || -z "$MAX_IDLE" ]]; then
    echo "Usage: $0 <wg_interface> <max_idle_seconds>"
    exit 1
fi

# 获取最近握手时间（时间戳）
LAST_HANDSHAKE=$(wg show "$WG_IFACE" latest-handshakes | awk '{print $2}')

# 当前时间戳
CURRENT_TIME=$(date +%s)

# 日志文件
LOG_FILE="/var/log/wg_monitor_${WG_IFACE}.log"

MAX_LOG_SIZE=1048576  # 1MB

if [ -f "$LOGFILE" ]; then
    LOG_SIZE=$(wc -c < "$LOGFILE")
    if [ "$LOG_SIZE" -gt "$MAX_LOG_SIZE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Log file too large ($LOG_SIZE bytes), cleared." > "$LOGFILE"
    fi
fi
# 检查是否有握手记录
if [[ -n "$LAST_HANDSHAKE" && "$LAST_HANDSHAKE" -ne 0 ]]; then
    DIFF=$((CURRENT_TIME - LAST_HANDSHAKE))
else
    DIFF=$((MAX_IDLE + 1))
fi

# 判断是否超时
if [ "$DIFF" -gt "$MAX_IDLE" ]; then
    echo "[$(date '+%F %T')] ⚠️ No handshake for ${DIFF}s, restarting $WG_IFACE..." >> "$LOG_FILE"
    ifdown "$WG_IFACE"
    sleep 2
    ifup "$WG_IFACE"
else
    echo "[$(date '+%F %T')] ✅ OK: Last handshake ${DIFF}s ago" >> "$LOG_FILE"
fi
