
build:
	docker build -t bergalath/bookworm-ruby:2.4-4 .

run:
	docker run -it --rm bergalath/bookworm-ruby:2.4-4 bash

push: build
	docker push bergalath/bookworm-ruby:2.4-4

setup:
	wget -qO- https://github.com/ruby/www.ruby-lang.org/raw/master/_data/releases.yml

# see https://github.com/docker-library/ruby/blob/abad497073efcd2537bb0a106c3515127bbccba4/Dockerfile.template
