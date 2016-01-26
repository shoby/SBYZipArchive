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

- (instancetype)initWithContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing *)error;

- (BOOL)loadEntriesWithError:(NSError *__autoreleasing *)error;

- (NSData *)dataForEntry:(SBYZipEntry *)entry error:(NSError *__autoreleasing *)error;

- (void)unzipEntry:(SBYZipEntry *)entry
             toURL:(NSURL *)url
           success:(void (^)(NSURL *unzippedFileLocation))success
           failure:(void (^)(NSError *error))failure
          progress:(void (^)(NSUInteger bytesUnzipped, NSUInteger totalBytes))progress;
@end


extern NSString* const SBYZipArchiveErrorDomain;

typedef NS_ENUM(NSInteger, SBYZipArchiveError)
{
    SBYZipArchiveErrorCannotOpenFile = 1,
    SBYZipArchiveErrorCannotGetFileInfo = 2,
    SBYZipArchiveErrorCannotUnzipEntryFile = 3,
};