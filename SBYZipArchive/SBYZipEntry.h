//
//  SBYZipEntry.h
//  SBYZipArchive
//
//  Created by shoby on 2013/12/30.
//  Copyright (c) 2013 shoby. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SBYZipArchive;

@interface SBYZipEntry : NSObject
@property (weak, nonatomic, readonly)   SBYZipArchive *archive;
@property (copy, nonatomic, readonly)   NSString  *fileName;
@property (assign, nonatomic, readonly) NSUInteger fileSize;
@property (assign, nonatomic, readonly) NSUInteger offset;

- (instancetype)initWithArchive:(SBYZipArchive *)archive
                       fileName:(NSString *)fileName
                       fileSize:(NSUInteger)fileSize
                         offset:(NSUInteger)offset;

// To unzip small file synchronously
- (NSData *)dataWithError:(NSError *__autoreleasing *)error;

// To unzip large file asynchronously
- (void)unzipToURL:(NSURL *)url
           success:(void (^)(NSURL *unzippedFileLocation))success
           failure:(void (^)(NSError *error))failure
          progress:(void (^)(NSUInteger bytesUnzipped, NSUInteger totalBytes))progress;

@end
