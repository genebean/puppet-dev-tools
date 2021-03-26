# specifying the platform here allows builds to work
# correctly on Apple Silicon machines
FROM --platform=amd64 puppet/pdk as base

ARG VCS_REF
ARG GH_USER=puppetlabs

LABEL org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.vcs-url="https://github.com/${GH_USER}/puppet-dev-tools"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq \
  && apt-get install -y locales \
  && sed -i -e 's/# \(en_US\.UTF-8 .*\)/\1/' /etc/locale.gen \
  && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get upgrade -y \
  && apt-get install -y --no-install-recommends curl libxml2-dev libxslt1-dev g++ gcc git gnupg2 make openssh-client wget zlib1g-dev \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

RUN ln -s /bin/mkdir /usr/bin/mkdir

# Use the PDK in unintended ways....
RUN ln -s /opt/puppetlabs/pdk/private/ruby/2.7.2/bin/bundle /usr/local/bin/bundle \
  && ln -s /opt/puppetlabs/pdk/private/ruby/2.7.2/bin/gem /usr/local/bin/gem \
  && ln -s /opt/puppetlabs/pdk/private/ruby/2.7.2/bin/rake /usr/local/bin/rake \
  && ln -s /opt/puppetlabs/pdk/private/ruby/2.7.2/bin/ruby /usr/local/bin/ruby

RUN groupadd --gid 1001 puppetdev \
  && useradd --uid 1001 --gid puppetdev --create-home -s /bin/bash puppetdev

# Prep for non-root user
RUN mkdir /setup \
  && chown -R puppetdev:puppetdev /setup \
  && mkdir /repo \
  && chown -R puppetdev:puppetdev /repo

# Switch to a non-root user for everything below here
USER puppetdev

# Install dependent gems
WORKDIR /setup
ADD Gemfile* /setup/
COPY Rakefile /Rakefile

RUN bundle install

WORKDIR /repo

FROM base AS rootless

FROM base AS main
USER root
