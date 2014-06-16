---
layout: post
title: "GIT tricks"
categories: git
abstract: "TODO"
---

# Copy a repository completely to a new destination

~~~ bash
$ git clone --bare https://github.com/myaccount/myrepo.git
$ cd myrepo
$ git push --mirror https://mydomain.com/git/mynewrepo.git
$ cd ..
$ rm -rf myrepo.git
~~~
