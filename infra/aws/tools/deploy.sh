#!/bin/bash

CWD=$(cd $(dirname $0) && pwd)
REPO_URL=$(bash $CWD/console.sh aws_ecr_repository.aws-module-ecs-repository.repository_url)

eval `aws ecr get-login --region ap-northeast-1 --no-include-email`
docker tag $1 $REPO_URL
docker push $REPO_URL

