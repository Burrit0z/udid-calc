//
//  main.m
//  udid-calc
//
//  Created by burrit0z on 2/25/21.
//

// POC manual udid calculation. This source file is not intended to be compiled,
// ever. Just copy the imports and code inside the getUDID function into your
// project.

#import <Foundation/Foundation.h>
#include <dlfcn.h>
#if !(__arm64e__)
#import <CommonCrypto/CommonDigest.h>
#endif

// Don't make it a function like this. Make it static and inline at the very
// minimum. Otherwise, one can dlopen your executable and use MobileSubstrate to
// very easily hook it, and all our work is for nothing.
NSString *getUDID() {
    // All of this below is equivalent to the one line:
    // NSString *UDID = (NSString *)CFBridgingRelease((CFStringRef)MGCopyAnswer(CFSTR("UniqueDeviceID")));
    // However, it does require linking agaist libMobileGestalt
    // The code below does not require linking against anything additional.

    // Use dlopen to get a handle on libMobileGestalt
    // This helps ensure we get the real function pointer so when we call it
    // we don't get a hooked version
    void *gestalt_handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_NOW);
    if(gestalt_handle == NULL) return;
    typedef CFPropertyListRef (*mgcopyanswer_ptr_t)(CFStringRef property);
    mgcopyanswer_ptr_t MGCopyAnswer = (mgcopyanswer_ptr_t)dlsym(gestalt_handle, "MGCopyAnswer");
    if(MGCopyAnswer == NULL) return;

#if __arm64e__

    // All we need for A12 is Chip ID and ECID
    NSNumber *chipIDNumber = (NSNumber *)CFBridgingRelease((CFStringRef)MGCopyAnswer(CFSTR("ChipID")));
    NSNumber *ecidNumber = (NSNumber *)CFBridgingRelease((CFStringRef)MGCopyAnswer(CFSTR("UniqueChipID")));

    // Convert to hex and pad with 0s
    // ChipID needs to be padded up to 8 characters, and ecid to 16
    NSString *chipid = [NSString stringWithFormat:@"%08llX", chipIDNumber.unsignedLongLongValue];
    NSString *ecid = [NSString stringWithFormat:@"%016llX", ecidNumber.unsignedLongLongValue];

    NSString *secret = [NSString stringWithFormat:@"%@-%@", chipid, ecid];

#else

    // On A11 and below, we have to use Security framework for CC_SHA1 (SHA1)
    // Same idea here, just dlopen it in order to get the function pointer
    // Enjoy the lovely one liner with the cast.
    void *security_handle = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_NOW);
    if(security_handle == NULL) return;
    typedef void (*ccsha1_ptr_t)(const void *data, long len, unsigned char *md);
    ccsha1_ptr_t CC_SHA1 = (ccsha1_ptr_t)dlsym(security_handle, "CC_SHA1");
    if(CC_SHA1 == NULL) return;

    // A11 and lower UDID = SHA1(serial + ecid + wifiAddress + bluetoothAddress)
    NSString *serial = (NSString *)CFBridgingRelease((CFStringRef)MGCopyAnswer(CFSTR("SerialNumber")));
    NSString *ecid = (NSString *)CFBridgingRelease((CFStringRef)MGCopyAnswer(CFSTR("UniqueChipID")));
    NSString *wifiAddress = (NSString *)CFBridgingRelease((CFStringRef)MGCopyAnswer(CFSTR("WifiAddress")));
    NSString *bluetoothAddress = (NSString *)CFBridgingRelease((CFStringRef)MGCopyAnswer(CFSTR("BluetoothAddress")));

    // Combine them
    NSString *combined = [NSString stringWithFormat:@"%@%@%@%@", serial, ecid, wifiAddress, bluetoothAddress];

    // Get our SHA1. This is why we need Security framework
    NSData *data = [combined dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);

    NSMutableString *secret = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [secret appendFormat:@"%02x", digest[i]];
    }

#endif

    // Send what we got.
    return secret;
}

// Obviously you would not have main in a tweak.
int main() {
    NSLog(@"UDID: %@", getUDID());
    return 0;
}
