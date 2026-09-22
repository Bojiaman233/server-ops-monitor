#!/bin/bash
# Nginx 访问日志增量分析脚本 web_collect.sh
# 功能：只分析上次读取之后新增的日志行，统计请求数/状态码/独立IP，写入 ops.web_stat

LOG=/var/log/nginx/access.log
POSFILE=/root/patrol/.last_line
TMP=/tmp/nginx_new.log

# 1. 读取上次读到第几行
LAST=$(cat $POSFILE 2>/dev/null || echo 0)
TOTAL=$(wc -l < $LOG)

# 2. 日志被轮转/清空时会倒退，重置为 0
if [ "$TOTAL" -lt "$LAST" ]; then
    LAST=0
fi

# 3. 取出新增部分到临时文件
tail -n +$((LAST + 1)) $LOG > $TMP

# 4. 更新位点
echo $TOTAL > $POSFILE

# 5. 统计各项指标
TOTAL_REQ=$(wc -l < $TMP)
R200=$(awk '$9==200' $TMP | wc -l)
R404=$(awk '$9==404' $TMP | wc -l)
R500=$(awk '$9==500' $TMP | wc -l)
UNIQ=$(awk '{print $1}' $TMP | sort -u | wc -l)

# 6. 打印出来肉眼确认
echo "$(date '+%Y-%m-%d %H:%M:%S') 新增请求=${TOTAL_REQ} 200=${R200} 404=${R404} 500=${R500} 独立IP=${UNIQ}"

# 7. 写入数据库
mysql -u root ops -e "INSERT INTO web_stat (stat_time,total_req,req_200,req_404,req_500,uniq_ip) VALUES (NOW(),$TOTAL_REQ,$R200,$R404,$R500,$UNIQ);"

