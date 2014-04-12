//
//  GLReceiveData.h
//  GPSCommunication
//
//  Created by Erik Larsen on 11/11/13.
//  Copyright (c) 2013 Erik Larsen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GLReceiveData <NSObject>

-(void)receiveData:(NSData *)buffer;


@end
