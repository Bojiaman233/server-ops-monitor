#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import pymysql
from datetime import date

conn = pymysql.connect(
    unix_socket='/var/run/mysqld/mysqld.sock',
    user='root',
    password='',
    database='ops',
    charset='utf8mb4',
    connect_timeout=5
    )

try:
    cur = conn.cursor()
    today = date.today().strftime('%Y-%m-%d')

    sql_sys = """
        SELECT COUNT(*),
               COALESCE(ROUND(AVG(cpu_usage), 2), 0),
               COALESCE(ROUND(MAX(cpu_usage), 2), 0),
               COALESCE(ROUND(AVG(mem_usage), 2), 0),
               COALESCE(ROUND(MAX(mem_usage), 2), 0),
               COALESCE(ROUND(AVG(disk_usage), 2), 0),
               COALESCE(ROUND(MAX(load_avg), 2), 0)
        FROM patrol_log
        WHERE DATE(check_time) = %s
    """
    cur.execute(sql_sys, (today,))
    s = cur.fetchone()

    sql_web = """
        SELECT COUNT(*),
               COALESCE(SUM(total_req), 0),
               COALESCE(SUM(req_200), 0),
               COALESCE(SUM(req_404), 0),
               COALESCE(SUM(req_500), 0),
               COALESCE(SUM(uniq_ip), 0)
        FROM web_stat
        WHERE DATE(stat_time) = %s
    """
    cur.execute(sql_web, (today,))
    w = cur.fetchone()

    line = "=" * 46
    print(line)
    print(f"服务器运维日报        {today}")
    print(line)
    print("[系统监控] patrol_log")
    print(f"  采样次数        : {s[0]}")
    print(f"  CPU   平均/峰值 : {s[1]}% / {s[2]}%")
    print(f"  内存  平均/峰值 : {s[3]}% / {s[4]}%")
    print(f"  磁盘  平均使用 : {s[5]}%")
    print(f"  负载1m 峰值    : {s[6]}")
    print("-" * 46)
    print("[网站访问] web_stat")
    print(f"  采集次数                  : {w[0]}")
    print(f"  总请求数                  : {w[1]}")
    print(f"  200 成功                  : {w[2]}")
    print(f"  404 缺失                  : {w[3]}")
    print(f"  500 错误                  : {w[4]}")
    print(f"  独立IP(各时段累计,非去重) : {w[5]}")
    print(line)

finally:
    conn.close()
