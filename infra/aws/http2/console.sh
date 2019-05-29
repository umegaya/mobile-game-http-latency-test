CWD=$(cd $(dirname $0) && pwd)

tfc() {
	docker run -i $1 -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
		-e AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
		-v /Users:/Users \
		-v $CWD:/tf -w /tf/resources hashicorp/terraform:light console
}

if [ $# -eq 0 ]; then
    tfc -t
else
    echo "$@" | tfc
fi
