//
//  SBYZipArchive.h
//  SBYZipArchive
//
//  Created by shoby on 2013/12/30.
//  Copyright (c) 2013 shoby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SBYZipEntry.h"

@protocol SBYZipArchiveDelegate;

@interface SBYZipArchive : NSObject
@property (strong, nonatomic, readonly) NSURL *url;
@property (readonly) NSArray *entries;
@property (weak, nonatomic) id<SBYZipArchiveDelegate> delegate;

- (id)initWithContentsOfURL:(NSURL *)url error:(NSError **)error;

- (BOOL)loadEntries:(NSError **)error;

- (NSData *)dataForEntry:(SBYZipEntry *)entry;
- (void)unzipEntry:(SBYZipEntry *)entry toURL:(NSURL *)url;
@end


@protocol SBYZipArchiveDelegate <NSObject>
- (void)zipArchive:(SBYZipArchive *)archive didUnzipEntry:(SBYZipEntry *)entry toURL:(NSURL *)url;
- (void)zipArchive:(SBYZipArchive *)archive didFailToUnzipEntry:(SBYZipEntry *)entry toURL:(NSURL *)url error:(NSError *)error;
@end


extern NSString* const SBYZipArchiveErrorDomain;

typedef NS_ENUM(NSInteger, SBYZipArchiveError)
{
    SBYZipArchiveErrorCannotOpenFile = 1,
    SBYZipArchiveErrorCannotGetFileInfo = 2,
    SBYZipArchiveErrorCannotUnzipEntryFile = 3,
};