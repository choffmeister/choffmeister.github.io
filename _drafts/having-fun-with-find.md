---
layout: post
title: "Having fun with find"
categories: unix
abstract: "TODO"
---

~~~
find / -name '*.log' -type f -mtime -1 -exec grep -Hn java {} \; 2>/dev/null
~~~
