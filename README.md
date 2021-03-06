# NuvlaBox Compute API

[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg?style=for-the-badge)](https://github.com/nuvlabox/compute-api/graphs/commit-activity)
[![GitHub issues](https://img.shields.io/github/issues/nuvlabox/compute-api?style=for-the-badge&logo=github&logoColor=white)](https://GitHub.com/nuvlabox/compute-api/issues/)
[![Docker pulls](https://img.shields.io/docker/pulls/nuvlabox/compute-api?style=for-the-badge&logo=Docker&logoColor=white)](https://cloud.docker.com/u/nuvlabox/repository/docker/nuvlabox/compute-api)
[![Docker image size](https://img.shields.io/microbadger/image-size/nuvlabox/compute-api?style=for-the-badge&logo=docker&logoColor=white)](https://cloud.docker.com/u/nuvlabox/repository/docker/nuvlabox/compute-api)

![CI Build](https://github.com/nuvlabox/compute-api/actions/workflows/main.yml/badge.svg)
![CI Release](https://github.com/nuvlabox/compute-api/actions/workflows/release.yml/badge.svg)


**This repository contains the source code for the NuvlaBox Compute API - the microservice which is responsible for relaying the host's Docker socket via TCP, making the [NuvlaBox](https://sixsq.com/products-and-services/nuvlabox/overview) secure and non-disruptive to the hosting device.**

This microservice is an integral component of the NuvlaBox Engine.

---

**NOTE:** this microservice is part of a loosely coupled architecture, thus when deployed by itself, it might not provide all of its functionalities. Please refer to https://github.com/nuvlabox/deployment for a fully functional deployment

---

## Build the NuvlaBox Compute API

This repository is already linked with Travis CI, so with every commit, a new Docker image is released. 

There is a [POM file](pom.xml) which is responsible for handling the multi-architecture and stage-specific builds.

**If you're developing and testing locally in your own machine**, simply run `docker build .` or even deploy the microservice via the local [compose files](docker-compose.yml) to have your changes built into a new Docker image, and saved into your local filesystem.

**If you're developing in a non-master branch**, please push your changes to the respective branch, and wait for Travis CI to finish the automated build. You'll find your Docker image in the [nuvladev](https://hub.docker.com/u/nuvladev) organization in Docker hub, names as _nuvladev/compute-api:\<branch\>_.

## Deploy the NuvlaBox Compute API

### Prerequisites 

 - *Docker (version 18 or higher)*
 - *Docker Compose (version 1.23.2 or higher)*

### Environment variables

|                          	|                                                                                                                                                       	|
|-------------------------	|------------------------------------------------------------------------------------------------------------------------------------------------------	|
|           HOSTNAME 	| the hostname used as CN when generating the TLS credentials for the API 	|
| | |

### Launching the NuvlaBox Compute API

Simply run `docker-compose up --build`


## Test the NuvlaBox Compute API

This microservice is completely automated, meaning that as long as all the proper environment variables have been correctly set and the right dependencies have been met, the respective Docker container will start by itself, automatically generate TLS credentials (if not present yet) and relay Docker's socket via TCP onto port 5000.

You can check that the API is successfully running by doing: `curl -k https://localhost:5000/containers/json -k --cacert ca.pem --cert cert.pem --key key.pem`. 

The pem certificates can be found inside the running container, at /srv/nuvlabox/shared/.

## Contributing

This is an open-source project, so all community contributions are more than welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md)
 
## Copyright

Copyright &copy; 2019, SixSq Sàrl
