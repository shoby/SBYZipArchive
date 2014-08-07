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
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) SBYZipArchive *archive;

- (void)setUpArchive;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpArchive];
    
    [self setImageByPartialMatching];
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
    [self.archive loadEntries:&loadError];
    if (loadError) {
        NSLog(@"%@", loadError);
        return;
    }
}

- (void)setImageByPartialMatching
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fileName like %@", @"*cat*"];
    NSArray *filterdEntries = [self.archive.entries filteredArrayUsingPredicate:predicate];
    SBYZipEntry *entry = [filterdEntries firstObject];
    
    UIImage *image = [[UIImage alloc] initWithData:entry.data scale:[[UIScreen mainScreen] scale]];
    self.imageView.image = image;
}

@end
