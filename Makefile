.PHONY: lint template test deps clean

# Helm lint
lint:
	helm lint .

# Render templates (dry-run)
template:
	helm template nextcloud . --debug

# Run helm-unittest (requires helm-unittest plugin)
# Install: helm plugin install https://github.com/helm-unittest/helm-unittest
test:
	helm unittest .

# Update dependencies
deps:
	helm dependency update

# Clean up
clean:
	rm -rf charts/*.tgz

# Validate rendered templates against Kubernetes API
validate: deps
	helm template nextcloud . | kubectl apply --dry-run=client -f -

# Run all checks
all: deps lint template
