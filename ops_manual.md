# 运维手册（ops_manual.md）

## 1. 日常巡检看什么
- 资源趋势：mysql -u root -e "USE ops; SELECT * FROM patrol_log ORDER BY check_time DESC LIMIT 20;"
- 当日日报：cat /root/patrol/report/report_$(date +%F).txt
- 采集脚本运行日志：tail -50 /root/patrol/collect.log

## 2. 告警查看
告警写入 /root/patrol/alert.log：磁盘 > 80% 或 Nginx 停止。
查看：tail -20 /root/patrol/alert.log

## 3. 常用统计 SQL
SELECT AVG(cpu_usage) 平均CPU, MAX(cpu_usage) 峰值CPU FROM patrol_log WHERE DATE(check_time)=CURDATE();
SELECT DATE_FORMAT(check_time,'%Y-%m-%d %H:00') 小时, AVG(cpu_usage) 平均CPU, COUNT(*) 次数 FROM patrol_log GROUP BY 1 ORDER BY 1;
SELECT * FROM web_stat ORDER BY stat_time DESC LIMIT 20;

## 4. 日志轮转（防写满磁盘）
/etc/logrotate.d/patrol：
/root/patrol/*.log { daily rotate 7 compress missingok notifempty }
测试：logrotate -d /etc/logrotate.d/patrol

## 5. 备份
tar -czvf /root/patrol_backup_$(date +%F).tar.gz /root/patrol

## 6. 故障排查清单
1. systemctl status nginx mysql 看是否 active
2. ss -tuln 看端口 80/3306
3. tail -50 /root/patrol/collect.log 看脚本报错
4. crontab -l 确认任务在；脚本用绝对路径
5. df -h 看磁盘；cat /root/patrol/alert.log 看告警
