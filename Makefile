REQUIREMENT = requirements.txt

SRC = app.py app_test.py

.PHONY: build test
build: html

%:
	cd docs && make $@

test: clean build
	pycodestyle $(SRC)
	pydocstyle $(SRC)
	coverage run app_test.py && coverage report --fail-under=90 -m $(SRC)
