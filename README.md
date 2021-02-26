# udid-calc
Calculate UDID manually from MobileGestalt
Does **not** require linking against libMobileGestalt

Please see main.m

If you just want to get the UDID with no extra steps, literally just use the following line. You will have to link your project against libMobileGestalt:
```objc
NSString *UDID = (NSString *)CFBridgingRelease((CFStringRef)MGCopyAnswer(CFSTR("UniqueDeviceID")));
```
