FROM docker.io/swift:6.2.1-bookworm AS builder
ARG APP_NAME

RUN swift sdk install https://download.swift.org/swift-6.2.1-release/static-sdk/swift-6.2.1-RELEASE/swift-6.2.1-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz --checksum 08e1939a504e499ec871b36826569173103e4562769e12b9b8c2a50f098374ad

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
	&& apt-get -q update \
	&& apt-get -q full-upgrade -y \
	&& apt-get -q --no-install-recommends install -y \
		make


WORKDIR /app

# ------------------------------------------------------------
# Cache Swift package dependencies
# ------------------------------------------------------------
# Copy the package manifest files *first* – they change rarely.
COPY Package.swift .
COPY Package.resolved .

# Resolve (download) the dependencies once.
# If Package.swift or Package.resolved changes, this layer will rebuild.
RUN --mount=type=cache,target=.build,sharing=locked \
	swift package resolve

# ------------------------------------------------------------
# Copy the rest of the source code & build
# ------------------------------------------------------------
# Now copy everything else (the .swift files, etc.).
# Any change here will only re‑run the swift build, not the resolve step.
COPY . .

# Build using Makefile
RUN --mount=type=cache,target=.build,sharing=locked \
	make build && cp "$(make getpath APP_NAME=$APP_NAME)" /$APP_NAME



# --------------------------------------------------------------------
# 2️⃣  Runtime stage – a slim image that only contains the binary
# --------------------------------------------------------------------
FROM docker.io/alpine:3.22 AS runtime
ARG APP_NAME

WORKDIR /app

# Copy the compiled binary from the builder stage
# Replace “MyApp” with the name of your binary
COPY --from=builder /$APP_NAME /usr/local/bin/$APP_NAME

ENV APP_NAME $APP_NAME
# Set the entrypoint to run the binary
ENTRYPOINT exec "$APP_NAME"
