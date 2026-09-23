.PHONY: dependency lint template test docs docs-check verify

HELM_DOCS_ARGS = --chart-search-root . --chart-to-generate . --sort-values-order file --document-dependency-values --skip-version-footer

docs:
	helm-docs $(HELM_DOCS_ARGS) --template-files README.gotmpl
	helm-docs $(HELM_DOCS_ARGS) --template-files docs/values/README.gotmpl --output-file docs/values/README.md

docs-check:
	@set -eu; work=$$(mktemp -d); trap 'rm -rf "$$work"' EXIT; \
	for output in README.md docs/values/README.md; do \
	  template=$${output%.md}.gotmpl; \
	  helm-docs $(HELM_DOCS_ARGS) --template-files "$$template" --output-file "$$output" --dry-run > "$$work/rendered.md"; \
	  diff -u "$$output" "$$work/rendered.md" || { echo "Run make docs to refresh $$output"; exit 1; }; \
	done

dependency:
	helm dependency update test

lint: dependency
	helm lint --strict test

template: dependency
	helm template contoso test >/dev/null

test: dependency
	helm unittest --strict test

verify: docs-check lint template test
