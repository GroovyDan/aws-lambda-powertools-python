
target:
	@$(MAKE) pr

dev:
	pip install --upgrade pip poetry
	poetry install

dev-docs:
	cd docs && npm install

format:
	poetry run isort -rc aws_lambda_powertools tests example
	poetry run black aws_lambda_powertools tests

lint: format
	poetry run flake8

test:
	poetry run pytest -vvv --cov=./ --cov-report=xml

coverage-html:
	poetry run pytest --cov-report html

pr: lint test security-baseline complexity-baseline

build: pr
	poetry run build

build-docs:
	@$(MAKE) build-docs-website
	@$(MAKE) build-docs-api

build-docs-api: dev
	mkdir -p dist/api
	poetry run pdoc --html --output-dir dist/api/ ./aws_lambda_powertools --force
	mv -f dist/api/aws_lambda_powertools/* dist/api/
	rm -rf dist/api/aws_lambda_powertools

build-docs-website: dev-docs
	mkdir -p dist
	cd docs && npm run build
	cp -R docs/public/* dist/

docs-local:
	cd docs && npm run start

docs-api-local:
	poetry run pdoc --http : aws_lambda_powertools

security-baseline:
	poetry run bandit --baseline bandit.baseline -r aws_lambda_powertools

complexity-baseline:
	$(info Maintenability index)
	poetry run radon mi aws_lambda_powertools
	$(info Cyclomatic complexity index)
	poetry run xenon --max-absolute C --max-modules A --max-average A aws_lambda_powertools

#
# Use `poetry version <major>/<minor></patch>` for version bump
#
release-prod:
	poetry config pypi-token.pypi ${PYPI_TOKEN}
	poetry publish -n

release-test:
	poetry config repositories.testpypi https://test.pypi.org/legacy
	poetry config pypi-token.pypi ${PYPI_TEST_TOKEN}
	poetry publish --repository testpypi -n

release: pr
	poetry build
	$(MAKE) release-test
	$(MAKE) release-prod
