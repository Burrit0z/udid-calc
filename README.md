# udid-calc
Calculate UDID manually from MobileGestalt

If you just want to get the UDID with no extra steps, literally just use the following line and add MobileGestalt lib to your project:
```objc
NSString *UDID = (NSString *)CFBridgingRelease((CFStringRef)MGCopyAnswer(CFSTR("UniqueDeviceID")));
```

If you want to manually fetch the values from Gestalt and calculate yourself, use the contents of main.m.
This requires libMobileGestalt, and for lower than A12, you'll need the Security framework.
