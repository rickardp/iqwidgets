IQWidgets for iOS
=================

Reuseable GUI component library for devices running iOS.

License
-------

Licensed under the Apache License Version 2.0



How to build
------------

To use IQWidgets in your project, just add the .xcodeproj file to your existing project as a dependency. Edit the 

IQWidgets was created for XCode 4. It has not been tested with earlier versions of XCode. If your project uses XCode 3, there may be some migration work for the project file itself.


The screen recorder / VNC server
--------------------------------

One of the features currently in IQWidgets is a screen recorder / screen sharing facility. This is intended for building demo movies and doing live demos without having to have a projector cable plugged in.

This functionality is highly experimental and not intended for use in a production application (it uses a private API function, so it is not even allowed by Apple).

Please also note that the VNC function uses GPL source code, so you cannot use it freely in a closed source application.

The VNC function uses libvncserver (http://libvncserver.sourceforge.net/).