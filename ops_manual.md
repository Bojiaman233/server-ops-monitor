# 运维手册（ops_manual.md）

## 1. 日常巡检看什么
- 资源趋势：`mysql -u root -e "USE ops; SELECT * FROM patrol_log ORDER BY check_time DESC LIMIT 20;"`
- 当日日报：`cat /root/patrol/report/report_$(date +%F).txt`
- 采集脚本运行日志：`tail -50 /root/patrol/collect.log`

## 2. 告警查看
告警写入 `/root/patrol/alert.log`，两种：
- 磁盘使用率 > 80%
- Nginx 服务停止（检测 `systemctl is-active nginx` 非 active）
查看命令：`tail -20 /root/patrol/alert.log`

## 3. 常用统计 SQL
```sql
-- 当日 CPU 平均值与峰值
SELECT AVG(cpu_usage) 平均CPU, MAX(cpu_usage) 峰值CPU
FROM patrol_log WHERE DATE(check_time)=CURDATE();

-- 按小时看平均 CPU（定位高峰时段）
SELECT DATE_FORMAT(check_time,'%Y-%m-%d %H:00') 小时,
       AVG(cpu_usage) 平均CPU, COUNT(*) 次数
FROM patrol_log GROUP BY 1 ORDER BY 1;

-- Web 访问状态码分布（来自 web_stat）
SELECT * FROM web_stat ORDER BY stat_time DESC LIMIT 20;
```

## 4. 日志轮转（防止写满磁盘）

采集脚本每 5 分钟追加写日志，文件只增不减，长期运行会吃满磁盘。已配置 logrotate 自动轮转。

### 4.1 规则文件 `/etc/logrotate.d/patrol`
/root/patrol/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```
参数含义：`daily` 每天轮转 / `rotate 7` 只保留最近 7 份归档 / `compress` 归档压成 .gz
/ `missingok` 文件不存在不报错 / `notifempty` 空文件不轮转。

### 4.2 为什么放在 /etc/logrotate.d/
logrotate 主配置 `/etc/logrotate.conf` 里有 `include /etc/logrotate.d`，该目录下的文件都会被自动加载。
**定时执行由系统自带，不需要自己加 crontab**，两套机制并存：
- `/etc/cron.daily/logrotate`（本镜像触发时间约 17:00）
- systemd `logrotate.timer`（每天 00:00，可用 `systemctl status logrotate.timer` 查看下次触发时间）

`daily` 按**日历天**判断，同一天内已轮转过就跳过，因此一天只切一次。

### 4.3 常用命令
```bash
logrotate -d /etc/logrotate.d/patrol
logrotate -f -v /etc/logrotate.d/patrol
cat /var/lib/logrotate/status
```

### 4.4 实测效果（2026-09-22 首次轮转）
| 日志 | 轮转前 | 压缩后 | 压缩比 |
|---|---|---|---|
| collect.log | 93451 B | 9895 B | 约 9.4 : 1 |
| web.log | 105853 B | 6544 B | 约 16 : 1 |

轮转采用 create 模式（改名后新建空文件）。采集脚本每次由 cron 以新进程 `>>` 重新打开
文件，因此轮转不中断采集 —— 实测轮转后数分钟内新文件即有新记录写入。

## 5. 备份
```bash
tar -czvf /root/patrol_backup_$(date +%F).tar.gz /root/patrol
```

## 6. 故障排查清单
服务/脚本不工作，按序排查：
1. `systemctl status nginx mysql` 看服务是否 active
2. `ss -tuln` 看端口（80 / 3306）是否在监听
3. `tail -50 /root/patrol/collect.log` 看脚本报错
4. `crontab -l` 确认任务在；脚本内用绝对路径
5. `df -h` 看磁盘是否写满；`cat /root/patrol/alert.log` 看告警
