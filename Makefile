SHELL := /bin/bash
ARCH := $(GOARCH)
CURDIR = $(shell pwd)
TEST_PACKAGES = $(shell find . -name "*_test.go" | sort | rev | cut -d'/' -f2- | rev | uniq)
EXECUTABLE_NAME = $(shell basename $(shell pwd))

branchId := $(shell echo ${BRANCH_ID})
FMT_GITHUB_REF = $(shell git status | grep "On branch " | cut -d' ' -f3 | sed 's/[\/]/\\\//g')
FMT_GITHUB_REPO = github.com\/kraneware\/$(shell basename `git rev-parse --show-toplevel`)

.DEFAULT_GOAL := test

.PHONY: clean init test coverage coverage-checks build buildOnly buildApp buildPlugin buildDeps

announce:
	@echo Running in ${CURDIR}
	@echo Building ${EXECUTABLE_NAME}

clean: announce
	@rm -Rf target
	@rm -Rf vendor
	@rm -f ${EXECUTABLE_NAME}

init: clean
	@mkdir target
	@mkdir target/testing
	@mkdir target/bin
	@mkdir target/deploy
	@mkdir target/tools
	@curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b target/tools latest
	@target/tools/golangci-lint --version

deps: init
	go env GOPRIVATE=github.com/kraneware/* GOOS=darwin GOARCH=$(ARCH) build -v ./...

cleanup:
	gofmt -w .

linter: deps cleanup
	@target/tools/golangci-lint run --timeout 1h --enable-all --disable=typecheck

test: init
	@for package in $(TEST_PACKAGES); do \
	  echo Testing package $$package ; \
	  cd $(CURDIR)/$$package ; \
	  mkdir ${CURDIR}/target/testing/$$package ; \
	  ginkgo -r -race -covermode=atomic -coverprofile ${CURDIR}/target/testing/$$package/coverage.out | tee ${CURDIR}/target/testing/$$package/target.txt ; \
	  if [ "$${PIPESTATUS[0]}" -ne "0" ]; then exit 1; fi; \
	  grep "FAIL!" ${CURDIR}/target/testing/$$package/target.txt ; \
	  if [ "$$?" -ne "1" ]; then exit 1; fi; \
	  cat ${CURDIR}/target/testing/$$package/coverage.out >> ${CURDIR}/target/coverage_profile.out ; \
	done

coverage: test
	@for package in ${TEST_PACKAGES}; do \
	  export MIN_COVERAGE=95 ; \
	  echo Generating coverage report for $$package ; \
	  cd $(CURDIR)/$$package ; \
	  if [ -f test.config ]; then source test.config; fi; \
	  go tool cover -html=${CURDIR}/target/testing/$$package/coverage.out -o ${CURDIR}/target/testing/$$package/coverage.html ; \
	done

coverage-checks: coverage
	@for package in ${TEST_PACKAGES}; do \
	  export MIN_COVERAGE=100 ; \
	  cd $(CURDIR)/$$package ; \
	  if [ -f test.config ]; then source ./test.config; fi; \
	  echo Checking coverage for $$package at $$MIN_COVERAGE% ; \
	  export COVERAGE_PCT=`grep "coverage: " ${CURDIR}/target/testing/$$package/target.txt | cut -d' ' -f2` ; \
	  export COVERAGE=`echo $$COVERAGE_PCT | cut -d'.' -f1` ; \
	  if [ "$$COVERAGE" -lt "$$MIN_COVERAGE" ]; then echo - Coverage not met at $$COVERAGE_PCT. ; exit 1; fi ; \
	  echo "  Coverage passed with $$COVERAGE_PCT" ; \
	done

build: coverage-checks buildDeps

all: build buildApp

app: build buildApp

buildApp:
	echo "processing root dir (.) for executable build!!"; \
	env GOPRIVATE=github.com/kraneware/* GOOS=darwin GOARCH=$(ARCH) go build -o target/bin/${EXECUTABLE_NAME}; \
	echo "executable build successful!! ;)";

buildDeps:
	set -m # Enable Job Control     # build all inner packages in loop then build plugin .so or executable at very end in root dir
	@for f in $(TEST_PACKAGES); do \
  		echo "processing dir $${f}"; \
  		dir=$${f}; \
		cd $${dir} && env GOPRIVATE=github.com/kraneware/* GOOS=darwin GOARCH=$(ARCH) go build && cd ..; \
		if [ $$? -ne 0 ]; then \
  		  	echo "exiting on go build error: $$? "; \
  			exit 1; \
  		fi; \
	done; \
	wait < <(jobs -p);



