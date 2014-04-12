//
//  GLEarthmate.m
//  GPSCommunication
//
//  Created by Erik Larsen on 11/9/13.
//  Copyright (c) 2013 Erik Larsen. All rights reserved.
//

#import "GLEarthmateUSB.h"


static Boolean IOHIDDevice_GetLongProperty(IOHIDDeviceRef inIOHIDDeviceRef, CFStringRef inKey, long *outValue)
{
    Boolean result = FALSE;
    if ( inIOHIDDeviceRef )
    {
        assert( IOHIDDeviceGetTypeID() == CFGetTypeID(inIOHIDDeviceRef) );

        CFTypeRef tCFTypeRef = IOHIDDeviceGetProperty(inIOHIDDeviceRef, inKey);
        if ( tCFTypeRef )
        {
            // if this is a number
            if ( CFNumberGetTypeID() == CFGetTypeID(tCFTypeRef) )
            {
                // get it's value
                result = CFNumberGetValue( (CFNumberRef) tCFTypeRef, kCFNumberSInt32Type, outValue );
            }
        }
    }

    return (result);
}


//
// Static callbacks from HID Manager
//

static void Handle_DeviceRemovalCallback(void * inContext,
                                         IOReturn inResult,
                                         void * inSender,
                                         IOHIDDeviceRef inIOHIDDeviceRef)
{
    if (inResult != kIOReturnSuccess)
    {
        fprintf(stderr, "%s( context: %p, result: %x, sender: %p ).\n",
                __PRETTY_FUNCTION__, inContext, inResult, inSender);
        return;
    }
    GLEarthmateUSB *self = (__bridge GLEarthmateUSB *) inContext;

    [self closeAndReleaseDevice: inIOHIDDeviceRef];
}


static void Handle_DeviceMatchingCallback(void *inContext,
                                          IOReturn inResult,
                                          void *inSender,
                                          IOHIDDeviceRef inIOHIDDeviceRef)
{
    GLEarthmateUSB *controller = (__bridge GLEarthmateUSB *) inContext;

    [controller openAndInitDevice:inResult sender:inSender device:inIOHIDDeviceRef];
}


static void Handle_IOHIDDeviceInputReportCallback(void *          inContext,
                                                  IOReturn        inResult,
                                                  void *          inSender,
                                                  IOHIDReportType inType,
                                                  uint32_t        inReportID,
                                                  uint8_t *       inReport,
                                                  CFIndex         inReportLength)
{
    GLEarthmateUSB *self = (__bridge GLEarthmateUSB *) inContext;

    [self inputReport:inResult
               sender:inSender
                 type:inType
             reportID:inReportID
               report:inReport
               length:inReportLength];
}


@interface GLEarthmateUSB()

@property (nonatomic) IOHIDDeviceRef inIOHIDDeviceRef;

@end

@implementation GLEarthmateUSB

-(void) inputReport:(IOReturn)inResult
             sender:(void *)inSender
               type:(IOHIDReportType)inType
           reportID:(uint32_t)inReportID
             report:(uint8_t *)inReport
             length:(CFIndex) inReportLength
{
    unsigned int noOfValidBytes = inReport[1]; // Get number of bytes that matters in this report

    NSData *receivedBytes = [[NSData alloc] initWithBytes:&inReport[2] length:noOfValidBytes];

    if([self.receivedDataDelegate respondsToSelector:@selector(receiveData:)])
    {
        [self.receivedDataDelegate receiveData:receivedBytes];
    }

 }


- (void) closeAndReleaseDevice: (IOHIDDeviceRef) hidDeviceRef
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"DeviceRemoved"
                        object:self
                        userInfo:nil];
}


-(void) openAndInitDevice:(IOReturn) inResult sender:(void *) inSender device:(IOHIDDeviceRef) inIOHIDDeviceRef
{
    gHidDeviceRef= inIOHIDDeviceRef;
    long reportSize = 0;
    (void) IOHIDDevice_GetLongProperty(inIOHIDDeviceRef, CFSTR(kIOHIDMaxInputReportSizeKey), &reportSize);

    self.inIOHIDDeviceRef = inIOHIDDeviceRef;

    if (reportSize)
    {
        report = calloc(1, reportSize);
        if (report)
        {
            IOHIDDeviceRegisterInputReportCallback(inIOHIDDeviceRef,
                                                   report,
                                                   reportSize,
                                                   Handle_IOHIDDeviceInputReportCallback,
                                                   (__bridge void *)(self));

            uint8_t triggerReport[]     = { 0xc0, 0x12, 0x00, 0x00, 0x03};
            CFIndex reportLength = sizeof(triggerReport);

            // synchronous
            IOReturn ioReturn = IOHIDDeviceSetReport(inIOHIDDeviceRef,
                                                     kIOHIDReportTypeFeature,
                                                     0,
                                                     triggerReport,
                                                     reportLength);
            if (kIOReturnSuccess != ioReturn)
            {
                NSLog(@"%s, IOHIDDeviceSetReport error: %d (0x%08X)", __PRETTY_FUNCTION__, ioReturn, ioReturn);
            }

        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DeviceAdded" object:self userInfo:nil];
}

- (void)sendReport
{
    static int wait = 0;
    return;
    //   if(wait++ == 100)
    {
        uint8_t triggerReport[]     = {'$', 'G', 'D', 'V', 0x00};
        CFIndex reportLength = sizeof(triggerReport);

        // synchronous
        IOReturn ioReturn = IOHIDDeviceSetReport(self.inIOHIDDeviceRef,
                                                 kIOHIDReportTypeOutput,
                                                 0,
                                                 triggerReport,
                                                 reportLength);
        if (kIOReturnSuccess != ioReturn)
        {
            NSLog(@"%s, IOHIDDeviceSetReport error: %d (0x%08X)", __PRETTY_FUNCTION__, ioReturn, ioReturn);
        }

        wait = 0;
    }


}

- (void) setupHidManagerAndCallbacks
{
    gHIDManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    if (gHIDManager) {
        NSDictionary * matchDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:0x1163], @kIOHIDVendorIDKey,
                                    [NSNumber numberWithInt:0x0100], @kIOHIDProductIDKey,
                                    nil];

        IOHIDManagerSetDeviceMatching(gHIDManager, (__bridge CFDictionaryRef) matchDict);

        // Callbacks for device plugin/removal
        IOHIDManagerRegisterDeviceMatchingCallback(gHIDManager, Handle_DeviceMatchingCallback, (__bridge void *)(self));
        IOHIDManagerRegisterDeviceRemovalCallback(gHIDManager, Handle_DeviceRemovalCallback, (__bridge void *)(self));

        // Schedule with the run loop
        IOHIDManagerScheduleWithRunLoop(gHIDManager, CFRunLoopGetCurrent( ), kCFRunLoopDefaultMode);

        IOReturn ioRet = IOHIDManagerOpen(gHIDManager, kIOHIDOptionsTypeNone);
        if (ioRet != kIOReturnSuccess) {
            CFRelease(gHIDManager);
            gHIDManager = NULL;
            NSLog(@"Failed to open the HID Manager");
        }
    }
}


- (id)init
{
    if (!(self = [super init]))
        return nil;

    buffer = [[NSMutableData alloc] initWithCapacity:20];

    [self setupHidManagerAndCallbacks];

    return self;
}


- (void)dealloc
{
    if (gHIDManager) {
        CFRelease(gHIDManager); // Should release our manager
        gHIDManager = NULL;
    }
    
}


@end