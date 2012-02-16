iCloudPlayground
================
Created by Leonhard Lichtschlag (leonhard@lichtschlag.net) on 13/Nov/11.  
Copyright (c) 2011 Leonhard Lichtschlag. All rights reserved.

------------------------- 

iCloudPlayground is a simple app that tests iCloud APIs. You can use it as a tutorial for simple 
iCloud tasks or to build upon for more advanced tasks.

To test this app you need to be either in the RWTH Aachen University team, or have access to 
another development team. If so, 

	1. go to the provisioning profile and be sure that for your app identifier is iCloud enabled, 
	2. exchange the app identifier in the info.plist,
	3. exchange the identifiers in the iCloud entitlements file,
	4. and of course, set your own developer profile in the build setting.

iCloud will not work in the simulator, so you need to test on a real device. And for testing out 
merge conflicts, you probably need a second device set to the same iCloud user ID.

------------------------- 

iCloud allows two kinds of syncing:

1. The key-value storage is basically NSUserDefaults shared among all devices with the same iCloud
   ID. I implemented this in the first tab. Some things worth mentioning:
	* The delay until a change propagates to other devices can be around 1 minute, so don't be
      surprised it it does not show up instantaneously.
	* The sharing is on key by key basis, so if you switch the first on iPhone A and the second in
	  iPhone B, both will be set in the end.
	* Without network access, the app still knows the old values, so no extra caching required.

2. The second sharing is on the basis of documents, see the second tab. I used the standard class 
   UIDocument for this. Some special things to note here:
	* Document sharing is much faster. The API documentation speaks of aggressive pushing over the 
	  cloud, and they do mean it. You should see a new document created on device A on device B 
	  within seconds.
	* Each document can be made "public" by asking the NSFilemanager for a cryptic URL on
	  [www.icloud.com](http://www.icloud.com/ "iCloud").
		* The link is built to be hard to guess and no password is required to access it. 
		* The caller can specify a date until the document is accessible under this URL.
		* If it is deleted locally, however, it also is no longer shared online.
		* The call to make the document public can take a few seconds.
	* Sharing the document to other apps on the device with UIDocumentInteractionController is 
	  possible directly out of the iCloud container.
	* If the contents of the file are changed at the same time on two devices and then synced, 
	  iCloud picks the newest one and discards all changes from the other.
		* UIDocument notifies this by reporting a merge conflict. It has to open the document once 
		  to notice this.
		* However, the merged document can directly be used again, the merge results in a working
		  document.
		* Further changes to the winning document do not discard the merge conflict, so in theory 
		  one can still go back and pick the discarded changes.
		* This means that for large documents with many merge conflicts, the programmer has to take 
		  care to resolve/discard the conflicts, so that little space is wasted.
	* In the iOS settings app and the iCloud pref pane on Lion, users can see space usage for the 
	  app.
		* If the documents are saved to {iCloud container}/Documents then the user can delete files 
		  from there as well.
		* Or the user might clear the whole contents of the iCloud container of this app identifier, 
		  deleting documents and all other helper files.

------------------------- 

Known bugs:

	* Closing a UIDocument a second time leads to a crash. 

------------------------- 

Possible expansions

	* With a core data backed document, iCloud can supposedly do more sophisticated merging.
	* One could display a merge UI to the user to pick one of the two possible files.

