#!/usr/bin/env bash

SCRIPTPATH="$( cd "$(dirname "$0")"; pwd -P)"
cd "$SCRIPTPATH"

scp -i "~/.ssh/keys/remotebuild.pem" -r ./deployment-compose.yml ec2-user@"$1":/home/ec2-user/docker-compose.yml
scp -i "~/.ssh/keys/remotebuild.pem" -r ./rust_config.yml ec2-user@"$1":/home/ec2-user/rust_config.yml
scp -i "~/.ssh/keys/remotebuild.pem" -r ./database.txt ec2-user@"$1":/home/ec2-user/.env
scp -i "~/.ssh/keys/remotebuild.pem" -r ./nginx_config.conf ec2-user@"$1":/home/ec2-user/nginx_config.conf
scp -i "~/.ssh/keys/remotebuild.pem" -r ../web_app/migrations ec2-user@"$1":/home/ec2-user/

echo "installing rust"
ssh -i "~/.ssh/keys/remotebuild.pem" -t ec2-user@"$1" << EOF
    curl https://sh.rustup.rs -sSf | bash -s -- -y
    until [ -f ./output.txt ]
    do
        sleep 2
    done
    echo "File Found"
EOF

echo "installing diesel"
ssh -i "~/.ssh/keys/remotebuild.pem" -t ec2-user@"$1" << EOF
  cargo install diesel_cli --no-default-features --features postgres
EOF

echo "building system"
ssh -i "~/.ssh/keys/remotebuild.pem" -t ec2-user@"$1" << EOF
  echo $3 | docker login --username $2 --password-stdin
  docker-compose up -d
  sleep 2
  diesel migration run
  curl --location --request POST 'http://localhost/v1/user/create' \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "name": "Matthew",
      "email": "test@gmail.com",
      "password": "test"
  }'
EOF
