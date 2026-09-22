#!/bin/bash
CPU=$(top -bn1 | grep "%Cpu" | awk -F',' '{printf "%.2f", 100-$4}')
MEM=$(free | grep Mem | awk '{printf "%.2f", $3/$2*100}')
DISK=$(df -P / | tail -1 | awk '{print $5}' | tr -d '%')
LOAD=$(awk '{print $1}' /proc/loadavg)
echo "CPU=${CPU}% 内存=${MEM}% 磁盘=${DISK}% 负载=${LOAD}"
mysql -u root ops -e "INSERT INTO patrol_log (check_time,cpu_usage,mem_usage,disk_usage,load_avg) VALUES (NOW(),$CPU,$MEM,$DISK,$LOAD);"

# 磁盘超阈值告警
if [ "$DISK" -gt 80 ]; then
    echo "[$(date '+%F %T')] 警告：磁盘使用率 ${DISK}%，超过阈值 80%" >> /root/patrol/alert.log
fi

# Nginx 存活检测
if ! systemctl is-active --quiet nginx; then
    echo "[$(date '+%F %T')] 警告：Nginx 服务已停止！" >> /root/patrol/alert.log
fi
