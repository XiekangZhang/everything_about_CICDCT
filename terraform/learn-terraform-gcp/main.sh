#!/bin/bash
# copy .sh from GCP Bucket to VM
gsutil -m cp -r "gs://playground-startup-script-bucket/my_script.sh" "/home/xiekang.zhang/my_script.sh"
# gcloud compute copy-files "./my_script.sh" "terraform-instance-internal-access:/home/xiekang.zhang/my_script.sh"

# chmod this file
chmod +x "/home/xiekang.zhang/my_script.sh"

# initial run
"/home/xiekang.zhang/my_script.sh"

# trigger
(crontab -l 2>/dev/null; echo "0,30 * * * * /home/xiekang.zhang/my_script.sh") | crontab -
