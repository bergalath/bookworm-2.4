FROM debian:bookworm

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		git \
		openssh-client \
# procps is very common in build systems, and is a reasonably small package
		procps \
		bzip2 \
		libffi-dev \
		libgmp-dev \
		libssl-dev \
		libyaml-dev \
		zlib1g-dev \
	; \
	rm -rf /var/lib/apt/lists/*

# skip installing gem documentation
RUN set -eux; \
	mkdir -p /usr/local/etc; \
	{ \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

ENV LANG=C.UTF-8
ENV RUBY_VERSION=2.4.10
ARG RUBY_DOWNLOAD_URL=https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.10.tar.gz
ARG RUBY_DOWNLOAD_SHA256=93d06711795bfb76dbe7e765e82cdff3ddf9d82eff2a1f24dead9bb506eaf2d0
# https://www.ruby-lang.org/en/news/2020/03/31/ruby-2-4-10-released/

# Bidouille pour installer OpenSSL 1.1.1w via ruby-build : bookworm fournit OpenSSL 3.0
ADD --chmod=755 https://raw.githubusercontent.com/rbenv/ruby-build/master/bin/ruby-build /usr/local/bin/ruby-build
ADD https://raw.githubusercontent.com/rbenv/ruby-build/master/share/ruby-build/$RUBY_VERSION /tmp/ruby-$RUBY_VERSION
RUN sed -i '/ruby-$RUBY_VERSION/d' /tmp/ruby-$RUBY_VERSION && \
    ruby-build /tmp/ruby-$RUBY_VERSION /usr/local

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
RUN set -eux; \
	buildDeps=' \
		bison \
		dpkg-dev \
		libgdbm-dev \
		ruby \
		autoconf \
		g++ \
		gcc \
		libbz2-dev \
		libgdbm-compat-dev \
		libglib2.0-dev \
		libncurses-dev \
		libreadline-dev \
		libxml2-dev \
		libxslt-dev \
		make \
		wget \
	'; \
	apt-get update; \
	apt-get install -y --no-install-recommends $buildDeps; \
		# https://github.com/docker-library/ruby/pull/438
	rm -rf /var/lib/apt/lists/*; \
	\
	wget -O ruby.tar.gz "$RUBY_DOWNLOAD_URL"; \
	echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum --check --strict; \
	\
	mkdir -p /usr/src/ruby; \
	tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1; \
	rm ruby.tar.gz; \
	\
	cd /usr/src/ruby; \
	\
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
	{ \
		echo '#define ENABLE_PATH_CHECK 0'; \
		echo; \
		cat file.c; \
	} > file.c.new; \
	mv file.c.new file.c; \
	\
	autoconf; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--disable-install-doc \
		--enable-shared \
	; \
	make -j "$(nproc)"; \
	make install; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false ruby; \
	rm -r /usr/src/ruby; \
# verify we have no "ruby" packages installed
	if dpkg -l | grep -i ruby; then exit 1; fi; \
	[ "$(command -v ruby)" = '/usr/local/bin/ruby' ]; \
# rough smoke test
	ruby --version; \
	gem update --system 3.3.27 --no-doc

# don't create ".bundle" in all our apps
ENV	GEM_HOME=/usr/local/bundle \
	BUNDLE_SILENCE_ROOT_WARNING=1
ENV	PATH=$GEM_HOME/bin:$PATH
RUN set -eux; \
	mkdir "$GEM_HOME"; \
# adjust permissions of GEM_HOME for running "gem install" as an arbitrary user
	chmod 1777 "$GEM_HOME"

CMD [ "irb" ]
