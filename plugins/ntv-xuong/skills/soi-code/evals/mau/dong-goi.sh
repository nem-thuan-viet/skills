#!/usr/bin/env bash
docker build -t ntv/erpnext:thu-nghiem .
docker cp ./app_gia erpnext-demo-backend-1:/home/frappe/frappe-bench/apps/
