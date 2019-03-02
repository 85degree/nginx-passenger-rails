FROM ubuntu:bionic-20190204
MAINTAINER Abdul Gaffur A Dama

ARG ruby_version=2.6.1
ARG nginxconf=/etc/nginx/nginx.conf

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

#Install all the reuirements 
RUN apt-get update
RUN apt-get install -y curl git build-essential zlib1g-dev libssl-dev libreadline-dev \
    libyaml-dev libcurl4-openssl-dev libffi-dev libcurl4-openssl-dev
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y nodejs yarn

RUN set -eux; \
	apt-get update; \
	apt-get install -y gosu; \
	rm -rf /var/lib/apt/lists/*; \
# verify that the binary works
	gosu nobody true

#Setup ENV variables
ENV PATH /usr/local/src/rbenv/shims:/usr/local/src/rbenv/bin:$PATH
ENV RBENV_ROOT /usr/local/src/rbenv
ENV RUBY_VERSION $ruby_version
ENV CONFIGURE_OPTS --disable-install-doc


RUN git clone https://github.com/rbenv/rbenv.git ${RBENV_ROOT} \
    && git clone https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build \
    && ${RBENV_ROOT}/plugins/ruby-build/install.sh

RUN echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh

RUN rbenv install $RUBY_VERSION \
&&  rbenv global $RUBY_VERSION
RUN gem install bundler

# install rails
RUN gem install rails

# install nginx
RUN apt-get install -y nginx

# install phussion passenger
RUN apt-get install -y dirmngr gnupg
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
RUN apt-get install -y apt-transport-https ca-certificates

RUN echo 'deb https://oss-binaries.phusionpassenger.com/apt/passenger bionic main' > /etc/apt/sources.list.d/passenger.list
RUN apt-get update
RUN apt-get install -y libnginx-mod-http-passenger

RUN if [ ! -f /etc/nginx/modules-enabled/50-mod-http-passenger.conf ]; then ln -s /usr/share/nginx/modules-available/mod-http-passenger.load /etc/nginx/modules-enabled/50-mod-http-passenger.conf ; fi

# gosu
RUN set -eux; \
	apt-get update; \
	apt-get install -y gosu; \
	rm -rf /var/lib/apt/lists/*; \
# verify that the binary works
	gosu nobody true

# restart nginx
EXPOSE 80

COPY ./entrypoint.sh /
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT [ "/entrypoint.sh" ]