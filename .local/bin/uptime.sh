#!/bin/bash
awk '{printf("%02d:%02d:%02d",($1/60/60%24),($1/60%60),($1%60))}' /proc/uptime
