# Convenience targets for building/publishing the image
IMAGE ?= erikskogh/jellyfin-tizen
TAG ?= latest

.PHONY: build run shell push clean

build:
	docker build -t $(IMAGE):$(TAG) .

run:
	docker run --rm -it -v jellyfin-tizen-home:/home/jellyfin --name jf-tizen $(IMAGE):$(TAG)

shell:
	docker run --rm -it -v jellyfin-tizen-home:/home/jellyfin --entrypoint bash $(IMAGE):$(TAG)

push:
	docker push $(IMAGE):$(TAG)

clean:
	docker rmi $(IMAGE):$(TAG) || true
