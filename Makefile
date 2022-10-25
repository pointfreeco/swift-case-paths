test-all: test-linux test-swift

test-linux:
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.3 \
		bash -c 'make test-swift'

test-swift:
	swift test \
 		--enable-test-discovery \
		--parallel
	swift test \
		-c release \
 		--enable-test-discovery \
		--parallel

format:
	swift format --in-place --recursive .

.PHONY: format test-all test-linux test-swift
