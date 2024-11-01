FROM buildpack-deps:bookworm

# skip installing gem documentation
RUN mkdir -p /usr/local/etc; \
    { \
      echo 'install: --no-document'; \
      echo 'update: --no-document'; \
    } >> /usr/local/etc/gemrc

ENV LANG=C.UTF-8
ENV RUBY_VERSION=2.4.10

# Bidouille pour installer OpenSSL 1.1.1w via ruby-build : bookworm fournit OpenSSL 3.0
ADD --chmod=755 https://raw.githubusercontent.com/rbenv/ruby-build/master/bin/ruby-build /usr/local/bin/ruby-build
ADD https://raw.githubusercontent.com/rbenv/ruby-build/master/share/ruby-build/$RUBY_VERSION /tmp/ruby-$RUBY_VERSION
RUN set -eux; \
    ruby-build /tmp/ruby-$RUBY_VERSION /usr/local; \
    rm -rf /tmp/*; \
    ruby --version; \
    gem update --system 3.3.27 --no-doc

CMD [ "irb" ]
