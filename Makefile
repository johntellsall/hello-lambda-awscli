BASIC_ROLE := arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

all:

# DEVELOP: invoke

run: invoke show-result show-log

invoke-raw:
	aws lambda invoke --function-name my-hello-function \
	/dev/stdout

IN_JSON='{"number": 5, "action": "increment"}'

invoke: check-cred
	aws lambda invoke \
		--cli-binary-format raw-in-base64-out \
		--function-name my-hello-function \
		--payload $(IN_JSON) \
		/dev/stdout

# DEVELOP: build/update

hello.zip: hello.py
	zip $@ $<

update: hello.zip check-cred
	aws lambda update-function-code \
	--function-name my-hello-function \
	--zip-file fileb://hello.zip

# DEVELOP: logs

logs:
	aws logs tail /aws/lambda/my-hello-function --format=short \
	| awk '/INFO/ {print $$3, substr($$0, index($$0, $$5))}'

logs-raw:
	aws logs describe-log-groups --query logGroups[*].logGroupName
	aws logs describe-log-streams \
	--log-group-name '/aws/lambda/my-hello-function' \
	--query logStreams[*].logStreamName

# MANAGE: create/delete

create-all: create-role create-function

create-function: hello.zip check-cred .role.arn
	egrep . .role.arn
	aws lambda create-function \
	--function-name my-hello-function \
	--runtime python3.6 \
	--role $$(cat .role.arn) \
	--handler hello.handler \
	--zip-file fileb://hello.zip \
	> .lambda.json
	jq '.FunctionArn' .lambda.json

create-role: check-cred
	aws iam create-role --role-name lambda-ex \
	--assume-role-policy-document file://trust-policy.json \
	| tee .role.json
	aws iam attach-role-policy --role-name lambda-ex \
	--policy-arn $(BASIC_ROLE)

delete-all: delete-role delete-function

delete-function:
	aws lambda delete-function --function-name my-hello-function

delete-role: check-cred
	-aws iam detach-role-policy --role-name lambda-ex \
	--policy-arn $(BASIC_ROLE)
	aws iam delete-role --role-name lambda-ex


# HELPERS

check-cred:
	aws sts get-caller-identity > /dev/null

clean:
	-$(RM) .role.json .role.arn .lambda.json

# DATA

.role.json:
	aws iam get-role --role-name lambda-ex | tee $@

.role.arn: .role.json
	jq -r .Role.Arn $< > $@
