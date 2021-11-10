from datetime import datetime
from datetime import timedelta

import os

def parse_job_time(start_line, end_line):
    # 2021-07-24T18:56:59.299 INFO filcrypto::proofs::api > seal_pre_commit_phase1: start
    # 2021-07-24T18:57:18.000 INFO filcrypto::proofs::api > seal_pre_commit_phase1: finish
    time_str1 = start_line.split()[0]
    time_str2 = end_line.split()[0]
    time_str1 = time_str1.split(".")[0]
    time_str2 = time_str2.split(".")[0]

    dt1 = datetime.strptime(time_str1, "%Y-%m-%dT%H:%M:%S")
    dt2 = datetime.strptime(time_str2, "%Y-%m-%dT%H:%M:%S")

    dt = dt2 - dt1
    return dt

def parse_log_file(filename, pattern, start, end):
    print(filename)
    with open(filename) as f:
        contents = f.readlines()
    # you may also want to remove whitespace characters like `\n` at the end of each line
    lines = [x.strip() for x in contents]

    job_times = []
    expect_end = False
    start_line = ""
    end_line = ""

    for line in lines:
        if pattern not in line:
            continue

        if start in line:
            start_line = line
            expect_end = True

        if end in line:
            if expect_end:
                end_line = line
                expect_end = False
                dt = parse_job_time(start_line, end_line)
                job_times.append(dt)
                continue
    return job_times

def print_log_job_times(time_list):
    if len(time_list) < 1:
        return

    min_time = time_list[0]
    max_time = time_list[0]
    avg_time = time_list[0]

    total = 0

    for dt in time_list:
        if dt > max_time:
            max_time = dt
        if dt < min_time:
            min_time = dt
        total = total + dt.total_seconds()

    avg_time = total / len(time_list)
    avg_time = timedelta(seconds=avg_time)

    print("count:",len(time_list), "min:", min_time, "max:", max_time, "avg:", avg_time)


def parse_c2_logs():
    line_pattern = "filcrypto::proofs::api > seal_commit_phase2"
    start_pattern = "start"
    end_pattern = "finish"

    for i in range(1, 3):
        os.system('grep {} /opt/lotusworker/worker-{}p2c2/log.txt  > /tmp/c2-{}.log'.format(now_time,i,i))
        filename = "/tmp/c2-{}.log".format(i)
        #filename = "worker-{}c2/log.txt".format(i)
        jts = parse_log_file(filename, line_pattern, start_pattern, end_pattern)
        print_log_job_times(jts)

now_time = datetime.now().strftime('%Y-%m-%d')
print("--------------------时间：{} C2-------------------------------".format(now_time))
parse_c2_logs()
