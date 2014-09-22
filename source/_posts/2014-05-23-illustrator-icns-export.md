---
layout: post
title: "Export Apple ICNS icon file from Adobe Illustrator"
date: "2014-05-23 23:21"
categories: macosx
abstract: "This post presents a small .jsx script for Adobe Illustrator (CS6) to directly export multiresolution ICNS icon file."
comments: true
---

When you develop an application for Mac OS X you need to supply an application icon in the Apple properitary ICNS icon format (see [here](http://en.wikipedia.org/wiki/Apple_Icon_Image_format)).

As it turns out the format is pretty simple. The different images are just concatenated. In between there have to be some header bytes and length information. Mac OS X 10.5 and above supports PNG images (which is the only inner format my script exports). To automate the task of exporting an icon in different resolutions and then packing them into an ICNS file I wrote a small export script.

You can find it at [GitHub](https://github.com/choffmeister/adobe-illustrator-icnsexport). Please feel free to contribute enhancements. The script is still very simple and might profit from some structural refactoring.
