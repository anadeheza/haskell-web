FROM haskell:9.6 AS builder

WORKDIR /app


COPY *.cabal ./
RUN cabal update && cabal build --only-dependencies


COPY . .
RUN cabal build && \
    cp $(cabal list-bin scotty-site) /app/scotty-site

FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && apt-get install -y libgmp10 ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/scotty-site ./scotty-site
COPY static ./static
COPY posts  ./posts

EXPOSE 3000

CMD ["./scotty-site"]
