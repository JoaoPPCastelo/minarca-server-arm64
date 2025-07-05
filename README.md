# minarca-arm64
Arm64 version of Minarca

## Build Image

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

## Docker Compose
You can use the container image published on Docker Hub to run minarca. Here's an example:
```yaml
services:
  minarca-server:
    image: joaoppcastelo/minarca-server-arm64:<TAG>
    ports:
      - "8080:8080"
      - "2222:22"
    volumes:
      # Location of the backups
      - ./backups:/backups
      # Configuration file and local database
      - ./conf:/etc/minarca
      # Application logs
      - ./logs:/var/log/minarca
    restart: always
    privileged: true
    environment:
      MINARCA_BRAND_HEADER_NAME: Test Backup Server
      # Define the URL to be used by users to connect to this container port 8080 running the webserver.
      #MINARCA_EXTERNAL_URL: https://minarca.mycompagny.com
      # Define the hostname and ip address to be used by Minarca Agent to connect to this container on port 2222 running SSH Server.
      MINARCA_MINARCA_REMOTE_HOST: localhost:2222
```

## Disclaimer
This is a arm64 version of the [Minarca project](https://minarca.org/en_CA). All the source code was developed and it's owned by Minarca developers. I just changed some configuration to make it work on arm64.

## Known Issues
1. For some reason could not run the `build-minarca-server` using "normal" `docker build` command. Had to use the workaround described here https://stackoverflow.com/a/72342814 
