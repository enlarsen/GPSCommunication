//
//  DumpViewController.m
//  GPSCommunication
//
//  Created by Erik Larsen on 11/9/13.
//  Copyright (c) 2013 Erik Larsen. All rights reserved.
//

#import "DumpViewController.h"

#define HEX_LINE_LENGTH 32 // How many bytes to decode per line of hex dump format
#define ASCII_LINE_LENGTH 1000 // How many bytes to decode per line of ascii format

@interface DumpViewController ()

@property (strong, nonatomic) GLEarthmateUSB *earthmate;
@property (strong, nonatomic) NSMutableArray *receivedData;
@property (strong, nonatomic) NSMutableArray *lineBuffer;
@end

@implementation DumpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.earthmate.receivedDataDelegate = self;
    }
    return self;
}

- (void)awakeFromNib
{
        self.earthmate.receivedDataDelegate = self;
    
}

- (GLEarthmateUSB *)earthmate
{
    if(!_earthmate)
    {
        _earthmate = [[GLEarthmateUSB alloc] init];
    }
    return _earthmate;
}

- (NSMutableArray *)receivedData
{
    if(!_receivedData)
    {
        _receivedData = [[NSMutableArray alloc] init];
    }
    return _receivedData;
}

- (NSMutableArray *)lineBuffer
{
    if(!_lineBuffer)
    {
        _lineBuffer = [[NSMutableArray alloc] init];
    }
    return _lineBuffer;
}

#pragma mark - Delegate method(s) to receive data from device

- (void)receiveData:(NSData *)buffer
{
    int i;

    for(i = 0; i < [buffer length]; i++)
    {
        uint8_t byte = ((uint8_t *)[buffer bytes])[i];

        [self.lineBuffer addObject:[NSNumber numberWithUnsignedChar:byte]];
    }

    if(self.lineBuffer.count < ASCII_LINE_LENGTH)
    {
        return;
    }

    [self formatLineAscii];

}

-(void)formatLineHex
{
    NSMutableString *line = [[NSMutableString alloc] init];
    NSMutableString *hexValues = [[NSMutableString alloc] init];
    NSMutableString *asciiValues = [[NSMutableString alloc] init];

    for(int i = 0; i < HEX_LINE_LENGTH; i++)
    {
        uint8_t byte = [(NSNumber *)self.lineBuffer[i] unsignedCharValue];
        [hexValues appendFormat:@"%0.2x", byte];
        if(isprint(byte))
        {
            [asciiValues appendFormat:@"%c", byte];
        }
        else
        {
            [asciiValues appendString:@"."];
        }

        // put two extra spaces after every eigth byte
        if(!((i+1) % 8))
        {
            [hexValues appendString:@"  "];
        }
    }

    [line appendFormat:@"%@    %@\n", hexValues, asciiValues];

    [self.textView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:line]];
    [self.textView scrollRangeToVisible:NSMakeRange([[self.textView string] length], 0)];

    NSRange deletionRange = {.location = 0, .length = HEX_LINE_LENGTH};
    [self.lineBuffer removeObjectsInRange:deletionRange];

}

-(void)formatLineAscii
{
    NSMutableString *asciiValues = [[NSMutableString alloc] init];

    for(int i = 0; i < [self.lineBuffer count]; i++)
    {
        uint8_t byte = [(NSNumber *)self.lineBuffer[i] unsignedCharValue];
        [asciiValues appendFormat:@"%c", byte];

    }
    [self.textView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:asciiValues]];
    [self.textView scrollRangeToVisible:NSMakeRange([[self.textView string] length], 0)];

    NSRange deletionRange = {.location = 0, .length = [self.lineBuffer count]};
    [self.lineBuffer removeObjectsInRange:deletionRange];
    

}


@end
