---
layout: post
title: "Use Docker 1.6.2 on CircleCI"
date: 2015-07-08 17:03:59 +0100
comments: true
categories: docker ci circleci
---

When using [Docker][docker] on [CircleCI][circleci], by default you can only use Docker 1.4.1 which is already pretty outdated. As confirmed by the CircleCI support, since some days you get more and more 4xx error when pulling from the official Docker registry. But there is a simple trick, to upgrade to Docker 1.6.2. See the following example CircleCI configuration file:

```
# circle.yml
machine:
  pre:
    - sudo curl -L -o /usr/bin/docker 'http://s3-external-1.amazonaws.com/circle-downloads/docker-1.6.2-circleci'; sudo chmod 0755 /usr/bin/docker; true
  services:
    - docker

test:
  pre:
    - docker pull busybox
```

Now you are running the official CircleCI Docker 1.6.2 build.

[docker]: https://www.docker.com/
[circleci]: https://circleci.com/
