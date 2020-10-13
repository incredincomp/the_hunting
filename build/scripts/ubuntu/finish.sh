#!/bin/bash -e
mv ~/backup-files/.aws ~/
cp ~/backup-files/* ~/the_hunting/backup-files/
# S3_ENDPOINT="$(cat /root/the_hunting/backup-files/s3-endpoint.txt)"
# S3_BUCKET="$(cat /root/the_hunting/backup-files/s3-bucket.txt)"
# export S3_ENDPOINT=$S3_ENDPOINT
# export S3_BUCKET=$S3_BUCKET
# systemctl daemon-reload
rm -rf /etc/update-motd.d/*
chmod +x /etc/init.d/
systemctl enable rc-local
