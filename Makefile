.PHONY: dependency lint template test verify

dependency:
	helm dependency update test

lint: dependency
	helm lint --strict test

template: dependency
	helm template contoso test >/dev/null

test: dependency
	helm unittest --strict test

verify: lint template test
