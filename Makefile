.PHONY: all build run setup list_targets log

NAMESPACE = ibm1@19ft.com_craft

choose: build-choose run-choose
counts: build-counts run-counts

build: build-choose build-increment-drink-count build-counts

# ------------------------------------------------------------------------------
# targets for  choose action

build-choose:
	cat actions/_common.swift actions/choose.swift > build/choose.swift
	wsk action update DC/choose build/choose.swift \
		--annotation description 'Choose me a drink' \
		--annotation final true --annotation web-export true

# CLI: curl -i -H 'Accept: application/json' https://openwhisk.ng.bluemix.net/api/v1/experimental/web/ibm1@19ft.com_craft/DC/choose.http
run-choose:
	curl -s -i -H 'Content-Type: application/json' -H 'Accept: application/json' \
	https://openwhisk.ng.bluemix.net/api/v1/experimental/web/$(NAMESPACE)/DC/choose.http


# ------------------------------------------------------------------------------
# targets for counts action

build-counts:
	cat lib/Redis/Redis*.swift actions/_common.swift actions/counts.swift > build/counts.swift
	wsk action update DC/counts build/counts.swift \
		--annotation description 'Count the drinks' \
		--annotation final true --annotation web-export true

# CLI: curl -i -H 'Accept: application/json' https://openwhisk.ng.bluemix.net/api/v1/experimental/web/ibm1@19ft.com_craft/DC/counts.http
run-counts:
	curl -s -i -H 'Content-Type: application/json' -H 'Accept: application/json' \
	https://openwhisk.ng.bluemix.net/api/v1/experimental/web/$(NAMESPACE)/DC/counts.http


# ------------------------------------------------------------------------------
# targets for incrementDrinkCount action

build-increment-drink-count:
	cat lib/Redis/Redis*.swift actions/_common.swift actions/incrementDrinkCount.swift > build/incrementDrinkCount.swift
	wsk action update DC/incrementDrinkCount build/incrementDrinkCount.swift \
		--annotation description 'Increment the drink counter' \
		--annotation final true --annotation web-export true


# ------------------------------------------------------------------------------
# misc

lastlog:
	wsk activation list -l1 | tail -n1 | cut -d ' ' -f1 | xargs wsk activation logs

setup:
	# Create package
	wsk package update DC --param-file parameters.json



# ------------------------------------------------------------------------------
# Run the action from the command line

action-choose:
	-wsk action invoke --blocking --result DC/choose --param type hot

action-counts:
	-wsk action invoke --blocking --result DC/counts

action-incrementDrinkCount:
	-wsk action invoke --blocking --result DC/incrementDrinkCount  --param name "A test drink"


# ------------------------------------------------------------------------------
# API Gateway targets

# Call the API endpoint: api_url=`wsk api-experimental list | grep DC/choose | awk 'END {print $NF}'`; curl -i $api_url;
api-endpoint-choose:
	wsk api-experimental create /DC/choose get DC/choose

# Call the API endpoint: api_url=`wsk api-experimental list | grep DC/count | awk 'END {print $NF}'`; curl -i $api_url;
api-endpoint-counts:
	wsk api-experimental create /DC/counts get DC/counts
