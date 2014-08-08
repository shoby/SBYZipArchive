//
//  ViewController.m
//  DemoApp
//
//  Created by shoby on 2014/05/04.
//  Copyright (c) 2014 shoby. All rights reserved.
//

#import "ViewController.h"
#import "SBYZipArchive.h"
#import "SBYZipEntry.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView01;
@property (weak, nonatomic) IBOutlet UIImageView *imageView02;

@property (strong, nonatomic) SBYZipArchive *archive;

- (void)setUpArchive;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpArchive];
    
    [self unzipImageSynchronously];
    [self unzipImageAsynchronously];
}

- (void)setUpArchive
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"images" withExtension:@"zip"];
    NSError *openError = nil;
    SBYZipArchive *archive = [[SBYZipArchive alloc] initWithContentsOfURL:url error:&openError];
    
    if (openError) {
        NSLog(@"%@", openError);
        return;
    }
    self.archive = archive;
    
    NSError *loadError = nil;
    [self.archive loadEntriesWithError:&loadError];
    if (loadError) {
        NSLog(@"%@", loadError);
        return;
    }
}

- (void)unzipImageSynchronously
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fileName like %@", @"*cat*"];
    NSArray *filterdEntries = [self.archive.entries filteredArrayUsingPredicate:predicate];
    SBYZipEntry *entry = [filterdEntries firstObject];
    
    NSData *data = [entry dataWithError:nil];
    UIImage *image = [[UIImage alloc] initWithData:data scale:[[UIScreen mainScreen] scale]];
    self.imageView01.image = image;
}


- (void)unzipImageAsynchronously
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fileName like %@", @"*dog*"];
    NSArray *filterdEntries = [self.archive.entries filteredArrayUsingPredicate:predicate];
    SBYZipEntry *entry = [filterdEntries firstObject];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [URLs objectAtIndex:0];
    
    [fileManager removeItemAtURL:[documentsDirectory URLByAppendingPathComponent:entry.fileName] error:nil];
    
    [entry unzipToURL:documentsDirectory success:^(NSURL *unzippedFileLocation) {
        NSData *data = [NSData dataWithContentsOfURL:unzippedFileLocation];
        UIImage *image = [[UIImage alloc] initWithData:data scale:[[UIScreen mainScreen] scale]];
        self.imageView02.image = image;
    } failure:^(NSError *error) {
        NSLog(@"%@", error);
    } progress:^(NSUInteger bytesUnzipped, NSUInteger totalBytes) {
        NSLog(@"progress:%f", (double)bytesUnzipped/totalBytes);
    }];
}

@end
