FROM ghcr.io/gleam-lang/gleam:v1.5.1-erlang-alpine

# Add project code
COPY . /build/

# Compile the project
RUN cd /build \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build

# Set the working directory
WORKDIR /app

# Set the entrypoint to run the Gleam project
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run", "pr"]