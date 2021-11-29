=======
# Project Team Members:
Jordan Wood
Clay Fricke
Logan Chayet
Jack Higgins
Preston 

# REPO ORGANIZATION:
Playswap.xcodeproj, PlaySwap.xcworkspace, and Main.storyboard cannot be viewed without XCode and will most likely be encrypted or look like gibberish xml. These files were originally auto generated when creating the project and the majority of our code in swift can be found in the ViewController.swift file. Main.storyboard is the file that an iPhone points to by default when trying to load the ui for an app. If you open this file in xcode, you will see an iphone with a sort of wireframe looking ui and a bar that says View Controller over it. This iphone screen is the main screen and is connected to our ViewController.swift. The resources folder contains all of our images and the mp4 thats played on the main screen. The Pods folder contains the packages we used for the project. The extensions folder contains some code for testing the spotify and apple music api's. Podfile and Podfile.lock are used for compiling and if there are any errors that pop up when you open the project, go to terminal and get into the main directory that has Podfile and type "pod install" you may have to look up how to install pod for this to work. TO ACTUALLY OPEN THE PROJECT: double click on PlaySwap.xcworkspace and the entire project should open in xcode if you have it. 


# HOW TO RUN AND ACCESS APP:
1) clone the main PlaySwap repo (found here: https://github.com/jwoody02/PlaySwap
2) download xcode from the mac app store (unfortunetly you cannot compile or view alot of the project without)
3) if you are on windows unfortunetly you can only view our code in a notepad and if this is the case go into the following directory: PlaySwap > PlaySwap > ViewControllers :: in here you will find ViewController.swift which contains the bulk of our viewable code on windows.
4) to actually open the project go into the PlaySwap folder and double click PlaySwap.xcworkspace to actually open the project in xcode
5) once opened, there may be an error or two that show up, if this happens first delete the "Pods" folder in the directory, go to terminal and cd into the directory with Podfile in it and type "pod install". If you dont have cocoapods installed you can do so with brew (look up online). 
6) To sign the app, you will also have to open the main PlaySwap file found on the upper left side of xcode which everything is a tree of. Once there press "Signing and capabilities" and create your own unique id and sign it with an apple developer account
7) after doing these steps there should be 0 errors and you can plug in your phone, select it from the devices at the top and press the play button.
8) on your phone, you have to go to settings > general > device management and VPNs :: and trust the app and your developer account and you should then be able to open it on your phone. If all of this is too much of a hastle, you can run it on one of the simulators listed in xcode and press play.


# Application Description:

Mobile app available to the public that can be used to transfer playlists to Spotify from Apple Music and vice versa. Of the large group of people that listen to music daily, there is a pretty even split between spotify and apple music. A big part of listening to music is sharing it with people you know, and as such, there is no reputable way of quickly and effectively transferring music between the platforms. Whatsmore, both platforms are competitive enough to the point that there is no official method of transferring playlists between the two platforms.

To fix a problem most people have encountered numerous times, we have decided to make an app that allows users to transfer playlists between the two platforms and only have to sign into one of them. Many solutions that already exist are complicated and require signing into both platforms. This is because these websites are intended to be used when the user is switching from one platform to the other and needs to transfer their private playlists. Our app would solve this problem but also give the user the ability to save other peoples playlists from other platforms with ease.

# Application Architecture:

The user accesses the application and transfers their playlist to a universal playlist type. Playlist gets sent to another user who opens it within their app and creates the playlist within their account on their music listening app. Uses Spotify and Apple Music APIs which have the functionality to create playlists and get songs from playlists. 
User interface will be done in swift. Python for connecting the front end to the APIs.

User may also search for playlists from both platforms whilst in the app and or paste the direct link to the playlist to start transfer. All songs can be transferred on device and saved to a playlist created by us as an exact duplicate. The user will then be redirected to the new playlist where they can listen/save.

Swift is used in IOS, Java is used in Android. Do we want a multi-OS app?
API for Python.
https://apple-music-python.readthedocs.io/en/latest/
https://spotipy.readthedocs.io/en/2.19.0/
