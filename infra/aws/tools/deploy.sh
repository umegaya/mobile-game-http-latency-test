#!/bin/bash

set -e

CWD=$(cd $(dirname $0) && pwd)
REPO_URL=$(bash $CWD/show.sh $1 module.ecr.aws_ecr_repository.aws-module-ecr-repository repository_url)

eval `aws ecr get-login --region ap-northeast-1 --no-include-email`
docker tag $2 $REPO_URL
docker push $REPO_URL

