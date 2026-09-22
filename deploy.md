# 部署手册（deploy.md）

## 1. 环境要求
- 操作系统：Ubuntu 22.04 LTS
- 软件：MySQL Server、Nginx、Python3、crontab
- Python 依赖：pymysql（Ubuntu 下用 apt install python3-pymysql 提供）

## 2. 安装基础软件
apt update
apt install -y mysql-server nginx
systemctl enable --now mysql nginx
apt install -y python3-pymysql

## 3. 创建数据库与数据表
登录 MySQL 后执行：
CREATE DATABASE IF NOT EXISTS ops DEFAULT CHARACTER SET utf8mb4;
USE ops;
CREATE TABLE patrol_log (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    check_time DATETIME,
    cpu_usage  DECIMAL(5,2),
    mem_usage  DECIMAL(5,2),
    disk_usage DECIMAL(5,2),
    load_avg   DECIMAL(5,2)
);
-- web_stat 字段以你服务器实际结构为准，执行下面命令确认后补全：
--   mysql -u root -e "SHOW CREATE TABLE ops.web_stat\G"

## 4. 部署脚本
cd /root/patrol
chmod +x collect.sh web_collect.sh

## 5. 配置定时任务
crontab -e
加入（% 需写成 \%）：
*/5 * * * * /root/patrol/collect.sh >> /root/patrol/collect.log 2>&1
*/5 * * * * /root/patrol/web_collect.sh >> /root/patrol/web.log 2>&1
59 23 * * * python3 /root/patrol/daily_report.py > /root/patrol/report/report_$(date +\%F).txt 2>&1
crontab -l

## 6. 验证
mysql -u root -e "USE ops; SELECT COUNT(*) FROM patrol_log;"
ls -lh /root/patrol/report/
tail -f /root/patrol/alert.log
