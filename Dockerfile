# STEP 1 - Build release compiler container
FROM elixir:1.20-otp-29-alpine AS builder

ENV APP_NAME=terrarest \
    MIX_ENV=prod

# Install build requirements
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache openssl-dev gcc ca-certificates git

WORKDIR /terrarest

RUN mix local.rebar --force && \
    mix local.hex --force

# Compile dependencies and application
COPY . .
RUN mix deps.get --only ${MIX_ENV}
RUN mix compile

# Create a release
RUN mkdir -p /opt/build && \
    mix release && \
    cp -r _build/${MIX_ENV}/rel /opt/build

# STEP 2 - Build application container
FROM alpine:3.24

ARG APP_NAME
ENV APP_NAME=${APP_NAME}

ENV ROOT_FOLDER=/opt

WORKDIR ${ROOT_FOLDER}

# Update kernel and install runtime dependencies
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache gcc bash openssl

# Copy the OTP binary from the build step
COPY --from=builder /opt/build .

ENV PATH="/opt/bin/:${PATH}"

RUN mkdir ${ROOT_FOLDER}/logs

# Create a non-root user
RUN adduser -D terrarest && \
    chown -R terrarest: ${ROOT_FOLDER}

USER terrarest

ENTRYPOINT ["/opt/rel/terrarest/bin/terrarest"]
CMD ["start"]
