#import <Foundation/Foundation.h>
#if !(__arm64e__)
#import <CommonCrypto/CommonDigest.h>
#endif

NSString *getUDID() {

    // Please note, this will not ensure the UDID you get is untampered with!
    // This is simply a way to calculate it manually, and using this over the one liner
    // does not mean it's more secure. It is just an alternative way.

    // All of this below is equivalent to the one line:
    // NSString *UDID = (NSString *)CFBridgingRelease((CFStringRef)MGCopyAnswer(CFSTR("UniqueDeviceID")));

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

    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [secret appendFormat:@"%02x", digest[i]];
    }

    #endif

    // Send what we got.
    return secret;

}

int main() {
    NSLog(@"UDID: %@", getUDID());
    return 0;
}
