# minarca-arm64
Arm64 version of Minarca

# Build Image

To build the image, and based on the know issue described bellow, you'll need to follow the steps below

1. Create a new image builder that allow insecure entitlement
```bash
docker buildx create --driver-opt image=moby/buildkit:master  \
    --use --name insecure-builder \
    --buildkitd-flags '--allow-insecure-entitlement security.insecure'
```

2. Configure docker buildx to use the new builder
```bash
docker buildx use insecure-builder
```

3. Build the image
```bash
docker buildx build --allow security.insecure -t minarca-server-arm64 -f minarca-server.Dockerfile --load .
```

Note: You only need to do the first step once, unless you remove the builder with
```bash
docker buildx rm insecure-builder
```


## Known Issues
1. For some reason could not run the `build-minarca-server` using "normal" `docker build` command. Had to use the workaround described here https://stackoverflow.com/a/72342814 
