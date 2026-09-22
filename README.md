# 服务器运维监控与日志分析系统

## 一、项目背景
模拟企业服务器「日常巡检 + 业务日志分析」场景，在云服务器（Ubuntu 22.04）上搭建一套自动化的运维监控工具：定时采集服务器资源指标并入库，分析 Nginx 访问日志，自动生成运维日报，并在指标异常或服务宕机时发出告警。

## 二、核心功能
- 每 5 分钟自动采集 CPU / 内存 / 磁盘 / 系统负载，写入 MySQL
- Nginx 访问日志分析：PV、独立访客(UV)、TOP10 访问 IP、HTTP 状态码分布
- Python 每日自动生成运维日报（含指标统计与异常提示）
- 磁盘使用率超阈值（>80%）或服务停止时，自动写入告警日志

## 三、技术栈
Linux(Ubuntu 22.04) · MySQL · Shell · Python3(pymysql) · Nginx · crontab

## 四、目录结构
/root/patrol/
├── collect.sh        资源指标采集 + 入库 + 告警脚本
├── web_collect.sh    Nginx 访问日志分析 + 入库脚本（增量位点读取）
├── daily_report.py   每日运维日报生成脚本（读库 → 打印 + 落文件）
├── README.md         项目说明（本文件）
├── deploy.md         部署手册（环境 / 建库建表 / 定时任务）
├── ops_manual.md     运维手册（巡检 / 告警 / 备份 / 故障排查）
├── .gitignore        忽略运行时日志与生成文件
├── collect.log       采集脚本运行日志（git 忽略）
├── web.log           日志分析脚本运行日志（git 忽略）
├── alert.log         告警日志（git 忽略）
└── report/           每日日报输出（git 忽略）

## 五、数据模型
- ops.patrol_log：巡检记录表，每行一次采集（时间 / CPU% / 内存% / 磁盘% / 负载）
- ops.web_stat：Web 访问统计结果表，每 5 分钟一个窗口（PV / UV / 各状态码计数 / 独立 IP 等）
> 详细建表 SQL 见 deploy.md。

## 六、自动化（crontab）
*/5 * * * * /root/patrol/collect.sh >> /root/patrol/collect.log 2>&1
*/5 * * * * /root/patrol/web_collect.sh >> /root/patrol/web.log 2>&1
59 23 * * * python3 /root/patrol/daily_report.py > /root/patrol/report/report_$(date +\%F).txt 2>&1

## 七、本地手动使用
cd /root/patrol
./collect.sh              # 立即采集一次
./web_collect.sh          # 立即分析一次日志
python3 daily_report.py   # 立即生成今日日报

## 八、部署与运维
- 部署步骤见 deploy.md
- 日常巡检、告警查看、备份与故障排查见 ops_manual.md
