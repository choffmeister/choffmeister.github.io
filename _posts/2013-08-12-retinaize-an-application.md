---
layout:     post
title:      "Retinaize an application"
date:       2013-08-12 06:45:21
categories: macos
---

If you have a Mac Book Pro with Retina display, you may stumble upon useful apps, that are not Retina ready by now. You can change this manually. Note, that this trick only works for the default Cocoa widgets. Custom GUI elements may remain non high definition.

To "upgrade" an application, open up a terminal and navigate to your Applications folder. Then use a terminal editor (I prefer vim):

```bash
$ cd /Applications
$ vim MyApplication.app/Contents/Info.plist
```

The Info.plist file is a simple XML file containing a key-value-store. The entry NSHighResolutionCapable is the one we are interested in. Add it (or update if already existent) with a value of true:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="0.9">
<dict>
	<!-- other entries -->
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
```

Mac OS seems to cache the Info.plist files. In order to force a reload just execute:

```bash
$ touch MyApplication.app
```

This updates the last changed timestamp in the file system. Now just start the app and enjoy the new crisp interface (for most of the widgets).

The following two picture show you the difference. I choose [MediaElch](http://www.mediaelch.de/) as an example for a not Retina ready application.

* [MediaElch original](/assets/images/mediaelch-original.png)
* [MediaElch retinaized](/assets/images/mediaelch-retinaized.png)

As you can see, the standard widgets like text boxes and labels look crisp afterwards, but other elements like icons stay pixelated.
