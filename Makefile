
# ------------------------------------------------------------------------------
# Variables
# NAMESPACE is your OpenWhisk namespace. Default to last item in `wsk namespace list`
# SLACK_TOKEN is the Slack API token from parameters.json
NAMESPACE = $(shell wsk namespace list | tail -n1)
SLACK_TOKEN = $(shell cat parameters.json |  python -c "import sys, json; print json.load(sys.stdin)['slack_verification_token']")


# ------------------------------------------------------------------------------
# Default target: update all actions into OpenWhisk if swift file changes
.PHONY: update
update: build/slackDrink.zip build/choose.zip build/incrementDrinkCount.zip build/counts.zip

# ------------------------------------------------------------------------------
# Build targets

# build slackDrink action
build/slackDrink.zip: actions/slackDrink.swift actions/_common.swift
	cat actions/_common.swift actions/slackDrink.swift > build/slackDrink.swift
	./compile.sh slackDrink
	wsk action update DC/slackDrink build/slackDrink.zip --kind swift:3.1.1 \
		--annotation description 'Process Slack /drink command' \
		--annotation final true --annotation web-export true


# build choose action
build/choose.zip: actions/choose.swift actions/_common.swift
	cat actions/_common.swift actions/mywhisk.swift actions/choose.swift > build/choose.swift
	./compile.sh choose
	wsk action update DC/choose build/choose.zip --kind swift:3.1.1 \
		--annotation description 'Choose me a drink' \
		--annotation final true --annotation web-export true


# build incrementDrinkCount action
build/incrementDrinkCount.zip: actions/incrementDrinkCount.swift actions/_common.swift
	cat lib/Redis/Redis*.swift actions/_common.swift actions/incrementDrinkCount.swift > build/incrementDrinkCount.swift
	./compile.sh incrementDrinkCount
	wsk action update DC/incrementDrinkCount build/incrementDrinkCount.zip --kind swift:3.1.1 \
		--annotation description 'Increment the drink counter' \
		--annotation final true --annotation web-export true


# build counts action
build/counts.zip: actions/counts.swift actions/_common.swift
	cat lib/Redis/Redis*.swift actions/_common.swift actions/counts.swift > build/counts.swift
	./compile.sh counts
	wsk action update DC/counts build/counts.zip --kind swift:3.1.1 \
		--annotation description 'Count the drinks' \
		--annotation final true --annotation web-export true



# ------------------------------------------------------------------------------
# Run targets
.PHONY: slackDrink choose counts incrementDrinkCount

slackDrink: build/slackDrink.zip
	curl -s -X POST -H 'Content-Type: application/json' -H 'Accept: application/json' \
	-d '{"command": "/drink", "channel_id": "C3JDU7G20", "channel_name": "atest", "user_id": "A123BCDE4", "user_name": "akrabat", "response_url": "", "token": "$(SLACK_TOKEN)", "text": "please"}' \
	https://openwhisk.ng.bluemix.net/api/v1/experimental/web/$(NAMESPACE)/DC/slackDrink.http

choose:
	curl -s -i -H 'Content-Type: application/json' -H 'Accept: application/json' \
	https://openwhisk.ng.bluemix.net/api/v1/experimental/web/$(NAMESPACE)/DC/choose.http


counts:
	curl -s -i -H 'Content-Type: application/json' -H 'Accept: application/json' \
	https://openwhisk.ng.bluemix.net/api/v1/experimental/web/$(NAMESPACE)/DC/counts.http

incrementDrinkCount:
	cat lib/Redis/Redis*.swift actions/_common.swift actions/incrementDrinkCount.swift > build/incrementDrinkCount.swift
	wsk action update DC/incrementDrinkCount build/incrementDrinkCount.swift \
		--annotation description 'Increment the drink counter' \
		--annotation final true --annotation web-export true


# ------------------------------------------------------------------------------
# Misc targets
.PHONY: lastlog setup clean

lastlog:
	wsk activation list -l1 | tail -n1 | cut -d ' ' -f1 | xargs wsk activation logs

setup:
	# Create package
	wsk package update DC --param-file parameters.json

clean:
	rm -rf build/*.swift
	rm -rf build/*.zip
	rm -rf build/*.js
