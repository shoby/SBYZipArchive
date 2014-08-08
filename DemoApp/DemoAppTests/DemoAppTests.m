//
//  DemoAppTests.m
//  DemoAppTests
//
//  Created by shoby on 2014/05/04.
//  Copyright (c) 2014年 shoby. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SBYZipArchive.h"

@interface DemoAppTests : XCTestCase
@end

@implementation DemoAppTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testUnzip
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"images" withExtension:@"zip"];
    NSError *openError = nil;
    SBYZipArchive *archive = [[SBYZipArchive alloc] initWithContentsOfURL:url error:&openError];
    if (openError) {
        XCTFail(@"%@", openError);
    }
    
    NSError *loadError = nil;
    [archive loadEntries:&loadError];
    if (loadError) {
        XCTFail(@"%@", loadError);
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fileName like %@", @"*cat*"];
    NSArray *filterdEntries = [archive.entries filteredArrayUsingPredicate:predicate];
    SBYZipEntry *entry = [filterdEntries firstObject];
    
    XCTAssertEqualObjects(@"images/cat.jpg", entry.fileName, @"Unexpected fileName.");
    XCTAssertEqual(2125938, entry.size, @"Unexpected size.");
    XCTAssertEqual(6838243, entry.offset, @"Unexpected offset.");
}

@end
