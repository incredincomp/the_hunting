#!/bin/bash -e
cp ~/backup-files/passwd-s3fs /etc/passwd-s3fs
cp ~/backup-files/* ~/the_hunting/backup-files/
chmod 600 /etc/passwd-s3fs
S3_ENDPOINT="$(cat /root/the_hunting/backup-files/s3-endpoint.txt)"
S3_BUCKET="$(cat /root/the_hunting/backup-files/s3-bucket.txt)"
sed -i 's+.*{TEXT_TO_BE_REPLACED}*+ExecStart=s3fs '"$S3_BUCKET"' /root/the_hunting/s3-booty -o nonempty -o url='"$S3_ENDPOINT"'+' ~/the_hunting/backup-files/s3fs.service
cp ~/the_hunting/backup-files/s3fs.service /etc/systemd/system/s3fs.service
chmod 664 /etc/systemd/system/s3fs.service
systemctl daemon-reload
systemctl enable s3fs.service
apt update && apt upgrade -y
