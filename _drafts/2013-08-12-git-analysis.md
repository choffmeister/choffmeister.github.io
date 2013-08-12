---
layout:     post
title:      "GIT analysis"
date:       2013-08-12 20:54:56
categories: git
---

Using a SCM in software development has many advantages: The most imporant ones might be the ability to work in larger teams on the same project while preserving every senseful state of the development history. But IMHO there is another greate benefit: The history allows statistical investigation of the development process.

For GIT there are many great tools for analysing repositories. A small (unordered) excerpt:

* [GitHub](https://github.com/)
* [Gitmetrics](http://www.gitmetrics.com/)
* [gitinspector](https://code.google.com/p/gitinspector/)
* [GitStats](http://gitstats.sourceforge.net/)

For sure there are many more, but all those tools have one thing in common: They analyse a single repository on it's own. I'm interested in more universal facts. For this purpose I wrote a little tool, that queries GitHub for the most popular repositories. In fact most popular means the repositories that have been forked most often. Then it clones all the repositories locally (I apologize in advance ^^) and runs some statistical analyses. The aim is to find some statistical relations between. For example I expect that repositories with many forkes have a much more branched history.

But why guess, if we can measure. In the next time I plan to release some (hopefully interesting) evaluations.
