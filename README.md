# dind4j
[![License](https://img.shields.io/badge/License-Apache_2.0-7D287B.svg)](https://raw.githubusercontent.com/s4s0l/dind4j/master/LICENSE)
[![Docker Pulls](https://img.shields.io/docker/pulls/sasol/dind4j.svg)](https://hub.docker.com/r/sasol/dind4j/)
[![GitHub release](https://img.shields.io/github/release/s4s0l/dind4j.svg?style=plastic)](https://github.com/s4s0l/dind4j/releases/latest)


Docker in Docker image with Java 8 and docker-compose meant for running gradle builds.

## Versioning

See [releases on github](https://github.com/s4s0l/dind4j/releases) to pick you version.


## Info
This image is based on [docker:1.13.0-dind](https://hub.docker.com/r/_/docker/ "Docker Hub")
so it contains docker and can be a host for child docker containers. 
There is also docker-compose and openjdk8 (in the same manner as official 
[openjdk image](https://github.com/docker-library/openjdk/blob/0476812eabd178c77534f3c03bd0a2673822d7b9/8-jdk/alpine/Dockerfile "Source"))
included. 

Dind image runs dockerd in foreground so in order to use it you have to 
start linked image. This may be inconvenient especially when you
need to mount some directories to child containers during build. This
image allows to run commands along started docker daemon in background.

Because purpose of this image is to run builds, running them as root 
in container may lead to some side affects such as temporary files
left by build with root ownership. This image allows to pass an user ID
under which commands will be executed.
 
## Examples

### Building a gradle project

Assuming we are in gradle project directory we can do:

```$xslt
docker run --privileged \
    -e RUNASUID=$(id -u) \
    -w /build -v $(pwd):/build \
    --name dind4j-builder \
    --rm sasol/dind4j:latest \
    ./gradlew --no-daemon -gradle-user-home=.cache --project-cache-dir=.cache clean test
``` 
It will mount current directory as /build and run gradlew as user having id like
current user. Dependencies and other cached by gradle files will land in .cache
directory that will be found in projects directory. Add it to git ignore.
 
If RUNASUID variable is not set it will run as root.

### Running interactive command
To run bash:

```$xslt
docker run --privileged \
    -e RUNASUID=$(id -u) \
    --rm -ti sasol/dind4j:latest bash
```

### Running in CI

Can be used also to get newer version of docker in CI. Common case for travis or 
shippable where their versions are always few releases behind the latest.
shippable.yml example:

```$xslt
build:
  cache: true
  cache_dir_list:
    - $SHIPPABLE_BUILD_DIR/.cache
  pre_ci_boot:
    options: "-v $SHIPPABLE_BUILD_DIR:$SHIPPABLE_BUILD_DIR"
  ci:
    - >
      docker run --privileged -w /build -v ${SHIPPABLE_BUILD_DIR}:/build 
      --rm sasol/dind4j:latest
      ./gradlew --no-daemon --project-cache-dir=.cache --gradle-user-home=.cache clean test
```

Gitlab CI, Travis CI also works.