// -------------------------
// iCloudPlayground
// ------------------------- 

iCloudPlayground is a simple app that tests iCloud APIs. 

To test this app you need to be either in the RWTH Aachen University team, or have access to another development team. If so, 
	(1) go to the provisioning profile and be sure that for your app identifier iCloud is enabled, 
	(2) exchange the app identifier in the info.plist, 
	(3) exchange the identifiers in the iCloud entitlements file,
	(4) and of course, set your own developer profile in the build setting.

iCloud will not work in the simulator, so you need to test on a real device.

iCloud allows two kinds of syncing:
(1) The key-value storage is basically NSUserDefaults shared among all devices with the same iCloud ID. This is implemented in the first tab. 
* The delay until a change propagates to other devices can be around 1 minute, so don't be surprised it it does not show up instantaneously.
* The sharing is on key by key basis, so if you switch the first on iPhone A and the second in iPhone B, both will be set in the end.
* Without network access, the app still knows the old values, so no extra caching required

(2) The second sharing is on the basis of documents basis, this is only half implemented.

