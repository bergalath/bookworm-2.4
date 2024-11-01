#

MAKEFLAGS += --always-make --no-builtin-rules --warn-undefined-variables
.ONESHELL:
.SILENT:

variant = bookworm
image = bergalath/$(variant)-ruby:2.4-4

build:
	docker build -t $(image) .

run:
	docker run -it --rm $(image) bash

push: build
	docker push $(image)

setup: SHELL != which ruby
setup: .SHELLFLAGS := -ryaml -rerb -e
setup:
	rubygems = "3.3.27"; variant = "$(variant)"
	releases = `wget -qO- https://github.com/ruby/www.ruby-lang.org/raw/master/_data/releases.yml`
	ruby_info = YAML.load_stream(releases).flatten.find { |v| v["version"] == "2.4.10" }
	File.write "Dockerfile", ERB.new(File.read("Dockerfile.erb")).result(binding)

# see https://github.com/docker-library/ruby/blob/abad497073efcd2537bb0a106c3515127bbccba4/Dockerfile.template
