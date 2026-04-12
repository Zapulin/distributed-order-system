# Stage 1: Builder
FROM --platform=linux/amd64 ruby:3.4.8-slim AS builder

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libyaml-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN gem install bundler -v 4.0.4

COPY Gemfile Gemfile.lock ./

RUN bundle install --jobs 4 --retry 3

COPY . .

# Stage 2: Runtime
FROM --platform=linux/amd64 ruby:3.4.8-slim AS runtime

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    curl \
    libpq5 \
    libyaml-0-2 \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN gem install bundler -v 4.0.4

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

RUN useradd -m appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 3000

# Default: HTTP server. Override to "bundle exec karafka server" for the worker container.
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
