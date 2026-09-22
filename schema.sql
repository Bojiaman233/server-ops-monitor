-- 服务器运维监控与日志分析系统：完整建表语句
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

CREATE TABLE web_stat (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    stat_time DATETIME,
    total_req INT,
    req_200   INT,
    req_404   INT,
    req_500   INT,
    uniq_ip   INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
