
build:
	docker build -t bergalath/bookworm-ruby:2.4-3 .

run:
	docker run -it --rm bergalath/bookworm-ruby:2.4-3 bash

push: build
	docker push bergalath/bookworm-ruby:2.4-3

setup:
	wget -qO- https://github.com/ruby/www.ruby-lang.org/raw/master/_data/releases.yml
