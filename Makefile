#

MAKEFLAGS += --always-make --no-builtin-rules --warn-undefined-variables
.ONESHELL:
.SILENT:

variant = bookworm
image = bergalath/$(variant)-ruby:2.4-5

build: setup
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

# — paquets installés dans buildpack-deps, on ne veut pas les désinstaller en fait !
# Commandline: apt-get install -y --no-install-recommends ca-certificates curl netbase wget
# Commandline: apt-get install -y --no-install-recommends gnupg dirmngr
# Commandline: apt-get install -y --no-install-recommends bzr git mercurial openssh-client subversion procps
# Commandline: apt-get install -y --no-install-recommends
# autoconf automake bzip2 dpkg-dev file g++ gcc imagemagick libbz2-dev libc6-dev libcurl4-openssl-dev libdb-dev libevent-dev
# libffi-dev libgdbm-dev libglib2.0-dev libgmp-dev libjpeg-dev libkrb5-dev liblzma-dev libmagickcore-dev libmagickwand-dev
# libmaxminddb-dev libncurses5-dev libncursesw5-dev libpng-dev libpq-dev libreadline-dev libsqlite3-dev libssl-dev libtool
# libwebp-dev libxml2-dev libxslt-dev libyaml-dev make patch unzip xz-utils zlib1g-dev default-libmysqlclient-dev
# Commandline: apt-get install -y --no-install-recommends bison ruby
# Commandline: apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
