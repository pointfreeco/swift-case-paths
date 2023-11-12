SWIFT_DOCKER_IMAGE = swift:5.6

test-all: test-linux test-swift

test-linux:
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		$(SWIFT_DOCKER_IMAGE) \
		bash -c 'apt-get update && apt-get -y install make && make test-swift'

test-swift:
	swift test \
		--parallel
	swift test \
		-c release \
		--parallel

format:
	swift format --in-place --recursive .

.PHONY: format test-all test-linux test-swift
