
build:
	docker build -t bergalath/bookworm-ruby:2.4-2 .

run:
	docker run -it --rm bergalath/bookworm-ruby:2.4-2 bash

push: build
	docker push bergalath/bookworm-ruby:2.4-2
