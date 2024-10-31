FROM buildpack-deps:bookworm

# skip installing gem documentation
RUN set -eux; \
	mkdir -p /usr/local/etc; \
	{ \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

ENV LANG=C.UTF-8
ENV RUBY_VERSION=2.4.10
ARG RUBY_DOWNLOAD_URL=https://cache.ruby-lang.org/pub/ruby/ruby-$RUBY_VERSION.tar.xz
ARG RUBY_DOWNLOAD_SHA256=d5668ed11544db034f70aec37d11e157538d639ed0d0a968e2f587191fc530df

# Bidouille pour installer OpenSSL 1.1.1w via ruby-build : bookworm fournit OpenSSL 3.0
ADD --chmod=755 https://raw.githubusercontent.com/rbenv/ruby-build/master/bin/ruby-build /usr/local/bin/ruby-build
ADD https://raw.githubusercontent.com/rbenv/ruby-build/master/share/ruby-build/$RUBY_VERSION /tmp/ruby-$RUBY_VERSION
RUN sed -i '/ruby-$RUBY_VERSION/d' /tmp/ruby-$RUBY_VERSION && \
    ruby-build /tmp/ruby-$RUBY_VERSION /usr/local

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
RUN set -eux; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		bison \
		dpkg-dev \
		libgdbm-dev \
		ruby \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	wget -O ruby.tar.xz "$RUBY_DOWNLOAD_URL"; \
	echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum --check --strict; \
	\
	mkdir -p /usr/src/ruby; \
	tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1; \
	rm ruby.tar.xz; \
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
		--with-openssl-dir=/usr/local/openssl \
	; \
	make -j "$(nproc)"; \
	make install; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	\
	cd /; \
	rm -r /usr/src/ruby; \
# verify we have no "ruby" packages installed
	if dpkg -l | grep -i ruby; then exit 1; fi; \
	[ "$(command -v ruby)" = '/usr/local/bin/ruby' ]; \
# rough smoke test
	ruby --version; \
	gem update --system 3.3.27 --no-doc

# don't create ".bundle" in all our apps
ENV GEM_HOME=/usr/local/bundle
ENV BUNDLE_SILENCE_ROOT_WARNING=1
# ENV BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH=$GEM_HOME/bin:$PATH
RUN set -eux; \
	mkdir "$GEM_HOME"; \
# adjust permissions of GEM_HOME for running "gem install" as an arbitrary user
	chmod 1777 "$GEM_HOME"

CMD [ "irb" ]

RUN apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark > /dev/null; \
    find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
      | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
      | sort -u \
      | xargs -r dpkg-query --search \
      | cut -d: -f1 \
      | sort -u \
      | xargs -r apt-mark manual \
    ; \
