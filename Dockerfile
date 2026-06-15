# Turnkey image for the OntoPortal License Server (Rails 8.0.3 / Ruby 3.2.9).
# Build: docker build -t license_server .
# Run:   see docker-compose.yml (app + mysql + memcached).
FROM ruby:3.2.9-slim

# Overridable so the compose `test` service can build with the test gem group
# included; production excludes development/test/deployment.
ARG BUNDLE_WITHOUT="development:test:deployment"
ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="${BUNDLE_WITHOUT}" \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

# System deps: build toolchain + libmysqlclient (mysql2), git (the GitHub-sourced
# API client), node (terser/asset precompile), gettext/openssl/mysql-client (entrypoint).
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential git pkg-config default-libmysqlclient-dev libyaml-dev \
      nodejs npm tzdata openssl ca-certificates default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN gem install bundler:2.7.2
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

# Precompile assets. production.rb requires a license_server_config_production.rb,
# so drop in the ENV-driven container config (defaults make it loadable with no
# env), precompile with a throwaway secret, then remove it — the entrypoint
# regenerates the real one from ENV at startup.
RUN cp docker/license_server_config.rb config/license_server_config_production.rb \
 && SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile \
 && rm -f config/license_server_config_production.rb

RUN chmod +x docker/entrypoint.sh

EXPOSE 3000
ENTRYPOINT ["docker/entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
