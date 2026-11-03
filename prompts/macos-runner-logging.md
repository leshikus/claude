# macOS runner logging

`ec2-macos-init` logs the output of the `ExecuteUserData` script only after the script exits: `executeCommand` collects it in a `bytes.Buffer` and calls `cmd.Run()`. A real-tool test on 2026-10-30 delivered 30 unbuffered lines after 33 seconds, none earlier.

`/var/log/amazon/ec2/ec2-macos-init.log` therefore holds no live output of `runner-init.py`, which never exits. The CloudWatch agent config (log group `runners/cloud-init-output`, stream = instance ID) is not at fault: a line appended to that file reached CloudWatch in about 16 seconds.

`runner-init.py` version 81 sends its stdout and stderr to `/Users/ec2-user/runner-init.log` (`config.log_file`), and `_retarget_macos_log_path` points the agent to that file (https://github.com/ClickHouse/ClickHouse/pull/128118). Fix logging in `runner-init.py`, not in `user_data_macos.txt`: a macOS `user_data` changes only while the instance is stopped, and each stop starts a host scrub that takes hours.

Before blaming the agent config, `tail` the file on the host to see whether it has the lines, then append a marker line and look for it in CloudWatch.
