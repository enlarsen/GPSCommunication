//
//  GLEarthmate.h
//  GPSCommunication
//
//  Created by Erik Larsen on 11/9/13.
//  Copyright (c) 2013 Erik Larsen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/hid/IOHIDManager.h>
#import "GLReceiveData.h"

@interface GLEarthmateUSB : NSObject {
    void *  report;
    IOHIDManagerRef gHIDManager;
    IOHIDDeviceRef gHidDeviceRef;
    NSMutableData *buffer;
}

@property (strong, nonatomic) id<GLReceiveData> receivedDataDelegate;

- (void) openAndInitDevice:(IOReturn)inResult sender:(void *)inSender device:(IOHIDDeviceRef)inIOHIDDeviceRef;
- (void) closeAndReleaseDevice: (IOHIDDeviceRef) hidDeviceRef;
- (void) inputReport:(IOReturn)inResult
              sender:(void *)inSender
                type:(IOHIDReportType)inType
            reportID:(uint32_t)inReportID
              report:(uint8_t*)inReport
              length:(CFIndex)inReportLength;

@end