//
//  SBYZipArchive.m
//  SBYZipArchive
//
//  Created by shoby on 2013/12/30.
//  Copyright (c) 2013 shoby. All rights reserved.
//

#import "SBYZipArchive.h"
#import "unzip.h"

NSString* const SBYZipArchiveErrorDomain = @"SBYZipArchiveErrorDomain";

static const NSUInteger SBYZipArchiveBufferSize = 4096;

@interface SBYZipArchive () <NSStreamDelegate>
@property (assign, nonatomic) unzFile unzFile;
@property (strong, nonatomic) NSMutableArray *cachedEntries;
@property (strong, nonatomic) dispatch_semaphore_t semaphore;
@property (strong, nonatomic) NSOutputStream *outputStream;
@property (strong, nonatomic) SBYZipEntry *unzipEntry;
@property (strong, nonatomic) NSURL *unzipURL;

- (NSString *)localizedDescriptionForUnzError:(int)unzError;
@end

@implementation SBYZipArchive

- (id)initWithContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing *)error
{
    self = [super init];
    if (self) {
        self.unzFile = unzOpen([url.path UTF8String]);
        if (!self.unzFile) {
            if (error) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Cannot open the archive file."};
                *error = [NSError errorWithDomain:SBYZipArchiveErrorDomain code:SBYZipArchiveErrorCannotOpenFile userInfo:userInfo];
            }
            return nil;
        }
        
        self.semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc
{
    unzClose(self.unzFile);
}

- (NSArray *)entries
{
    if (!self.cachedEntries) {
        [self loadEntries:nil];
    }
    return self.cachedEntries;
}

- (NSData *)dataForEntry:(SBYZipEntry *)entry
{
    if (!entry) {
        return nil;
    }
    
    // start lock
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
    dispatch_semaphore_wait(self.semaphore, timeout);
    
    unzSetOffset(self.unzFile, entry.offset);
    
    unzOpenCurrentFile(self.unzFile);
    
    NSMutableData *data = [[NSMutableData alloc] initWithLength:entry.size];
    unzReadCurrentFile(self.unzFile, [data mutableBytes], (unsigned int)data.length);
    
    unzCloseCurrentFile(self.unzFile);
    
    // end lock
    dispatch_semaphore_signal(self.semaphore);
    
    return data;
}

- (BOOL)loadEntries:(NSError **)error
{
    self.cachedEntries = [NSMutableArray array];
    
    unzGoToFirstFile(self.unzFile);
    while (true) {
        unz_file_info file_info;
        char file_name[256];
        
        int unz_err = unzGetCurrentFileInfo(self.unzFile, &file_info, file_name, sizeof(file_name), NULL, 0, NULL, 0);
        if (unz_err != UNZ_OK) {
            if (error) {
                NSString *localizedDescription = [self localizedDescriptionForUnzError:unz_err];
                *error = [NSError errorWithDomain:SBYZipArchiveErrorDomain code:SBYZipArchiveErrorCannotGetFileInfo userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
            }
            return NO;
        }
        
        NSUInteger offset = unzGetOffset(self.unzFile);
        
        NSString *fileName = [NSString stringWithUTF8String:file_name];
        SBYZipEntry *entry = [[SBYZipEntry alloc] initWithArchive:self fileName:fileName size:file_info.uncompressed_size offset:offset];
        
        [self.cachedEntries addObject:entry];
        
        if (unzGoToNextFile(self.unzFile) != UNZ_OK) {
            break;
        }
    }
    
    return YES;
}

- (NSString *)localizedDescriptionForUnzError:(int)unzError
{
    NSString * localizedDescription = nil;
    
    switch (unzError) {
        case UNZ_BADZIPFILE:
            localizedDescription = @"The archive file seems to be incorrect format.";
            break;
        case UNZ_ERRNO:
            localizedDescription = [NSString stringWithFormat:@"Failed to read file: %s", strerror(errno)];
            break;
        default:
            localizedDescription = @"Failed to read file";
            break;
    }
    
    return localizedDescription;
}

- (void)unzipEntry:(SBYZipEntry *)entry toURL:(NSURL *)url
{
    if (!entry) {
        return;
    }
    
    NSURL *fullPath = [url URLByAppendingPathComponent:entry.fileName];
    
    NSFileManager *fileManger = [[NSFileManager alloc] init];
    
    if ([fileManger fileExistsAtPath:fullPath.path]) {
        if (self.delegate) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Cannot unzip the entry file. File already exits."};
            
            NSError *error = [NSError errorWithDomain:SBYZipArchiveErrorDomain code:SBYZipArchiveErrorCannotUnzipEntryFile userInfo:userInfo];
            
            [self.delegate zipArchive:self didFailToUnzipEntry:entry toURL:url error:error];
        }
        
        return;
    }
    
    if (![fileManger fileExistsAtPath:[fullPath.path stringByDeletingLastPathComponent]]) {
        NSError *error = nil;
        [fileManger createDirectoryAtPath:[fullPath.path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (error) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to create directory."};
            NSError *error = [NSError errorWithDomain:SBYZipArchiveErrorDomain code:SBYZipArchiveErrorCannotUnzipEntryFile userInfo:userInfo];
            
            [self.delegate zipArchive:self didFailToUnzipEntry:entry toURL:url error:error];
            
            return;
        }
    }
    
    // start lock
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
    dispatch_semaphore_wait(self.semaphore, timeout);
    
    unzSetOffset(self.unzFile, entry.offset);
    unzOpenCurrentFile(self.unzFile);
    
    self.unzipEntry = entry;
    self.unzipURL = url;
    
    self.outputStream = [[NSOutputStream alloc] initWithURL:fullPath append:YES];
    self.outputStream.delegate = self;
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.outputStream open];
    
    // end lock
    dispatch_semaphore_signal(self.semaphore);
}

- (void)closeStream:(NSStream *)stream
{
    [stream close];
    [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.outputStream = nil;
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable:
        {
            NSMutableData *buffer = [[NSMutableData alloc] initWithLength:SBYZipArchiveBufferSize];
            int readBytes = unzReadCurrentFile(self.unzFile, [buffer mutableBytes], (unsigned int)buffer.length);
            
            if (readBytes == 0) { // completed
                if (self.delegate) {
                    [self.delegate zipArchive:self didUnzipEntry:self.unzipEntry toURL:self.unzipURL];
                }
                
                [self closeStream:stream];
            } else if (readBytes < 0) { // error
                int unz_err = readBytes;
                NSString *localizedDescription = [self localizedDescriptionForUnzError:unz_err];
                NSError *error = [NSError errorWithDomain:SBYZipArchiveErrorDomain code:SBYZipArchiveErrorCannotUnzipEntryFile userInfo:@{NSLocalizedDescriptionKey: localizedDescription}];
                
                if (self.delegate) {
                    [self.delegate zipArchive:self didFailToUnzipEntry:self.unzipEntry toURL:self.unzipURL error:error];
                }
                
                [self closeStream:stream];
            } else {
                [(NSOutputStream *)stream write:[buffer bytes] maxLength:readBytes];
            }
            
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            if (self.delegate) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to unzip the entry file."};
                
                NSError *error = [NSError errorWithDomain:SBYZipArchiveErrorDomain code:SBYZipArchiveErrorCannotUnzipEntryFile userInfo:userInfo];
                
                if (self.delegate) {
                    [self.delegate zipArchive:self didFailToUnzipEntry:self.unzipEntry toURL:self.unzipURL error:error];
                }
            }
            
            [self closeStream:stream];
        }
        case NSStreamEventEndEncountered:
        {
            if (self.delegate) {
                [self.delegate zipArchive:self didUnzipEntry:self.unzipEntry toURL:self.unzipURL];
            }
            
            [self closeStream:stream];
        }
        default:
            break;
    }
}

@end
