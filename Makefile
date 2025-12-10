.PHONY: lint template validate deps clean

# Helm lint
lint:
	helm lint .

# Render templates (dry-run)
template:
	helm template nextcloud . --debug

# Update dependencies
deps:
	helm dependency update

# Validate rendered templates against Kubernetes API
validate: deps
	helm template nextcloud . | kubectl apply --dry-run=client -f -

# Clean up
clean:
	rm -rf charts/*.tgz

# Run all checks
all: deps lint validate
