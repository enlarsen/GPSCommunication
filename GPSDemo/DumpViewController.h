//
//  DumpViewController.h
//  GPSCommunication
//
//  Created by Erik Larsen on 11/9/13.
//  Copyright (c) 2013 Erik Larsen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLEarthmateUSB.h"

@interface DumpViewController : NSViewController <GLReceiveData>

@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end
