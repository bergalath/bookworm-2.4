FROM buildpack-deps:bookworm

ENV LANG=C.UTF-8 \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    RUBY_VERSION=2.4.10

# Using https://github.com/rbenv/ruby-build to install OpenSSL 1.1 in bookworm
ADD --chmod=755 https://raw.githubusercontent.com/rbenv/ruby-build/master/bin/ruby-build /usr/local/bin/ruby-build
ADD https://raw.githubusercontent.com/rbenv/ruby-build/master/share/ruby-build/$RUBY_VERSION /tmp/ruby.build

RUN set -eux; \
    mkdir -p /usr/local/etc; \
    { \
      echo 'install: --no-document'; \
      echo 'update: --no-document'; \
    } >> /usr/local/etc/gemrc; \
    ruby-build /tmp/ruby.build /usr/local; \
    rm -rf /tmp/*; \
    ruby --version; \
    gem update --system 3.3.27 --no-doc

# # The unpleasant part : https://wiki.archlinux.org/title/Ruby#Configuration
# # https://felipec.wordpress.com/2023/02/27/fixing-ruby-gems-installation-part-2/
# # Set those two variables in your Dockerfile
# ENV GEM_HOME="$(gem env user_gemhome)"
# ENV PATH=$GEM_HOME/bin:$PATH

CMD [ "irb" ]
