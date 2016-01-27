//
//  YETIViewController.m
//  YetiCharacterLabelExample
//
//  Created by Andrew Hulsizer on 7/20/14.
//  Copyright (c) 2014 Swift Yeti. All rights reserved.
//

#import "YETIViewController.h"

#import "YETICharacterLabel.h"
#import "YETIFallingLabel.h"

#import "FlickrCollectionViewCell.h"
#import <FlickrKit/FlickrKit.h>
#import "FlickrPhoto.h"

@interface YETIViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) NSMutableArray *flickrPhotos;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet YETIFallingLabel *characterLabel;
@end

@implementation YETIViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[FlickrKit sharedFlickrKit] initializeWithAPIKey:@"insert_flickr_api_key_here" sharedSecret:@"insert_flickr_shared_secret_here"];
    
    [self.collectionView registerClass:[FlickrCollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([FlickrCollectionViewCell class])];
    [self.collectionView reloadData];
    
    FlickrKit *flickrKit = [FlickrKit sharedFlickrKit];
    FKFlickrInterestingnessGetList *interesting = [[FKFlickrInterestingnessGetList alloc] init];
    [flickrKit call:interesting completion:^(NSDictionary *response, NSError *error) {
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:error.localizedDescription message:error.localizedFailureReason delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            });
        } else if (response != nil) {
            // Note this is not the main thread!
            NSMutableArray *photoURLs = [NSMutableArray array];
            for (NSDictionary *photoData in [response valueForKeyPath:@"photos.photo"]) {
                FlickrPhoto *photo = [[FlickrPhoto alloc] init];
                photo.title = photoData[@"title"];
                photo.photoURL = [flickrKit photoURLForSize:FKPhotoSizeMedium800 fromPhotoDictionary:photoData];
                [photoURLs addObject:photo];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                // Any GUI related operations here
                self.flickrPhotos = photoURLs;
                [self.collectionView reloadData];
                [self scrollViewDidEndDecelerating:self.collectionView];
            });
        }
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.flickrPhotos count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FlickrCollectionViewCell *cell = (FlickrCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([FlickrCollectionViewCell class]) forIndexPath:indexPath];
    [cell configureWithFlickrPhoto:self.flickrPhotos[indexPath.row]];
    
    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger page = scrollView.contentOffset.x/CGRectGetWidth(self.view.bounds);
    FlickrPhoto *photo = self.flickrPhotos[page];
    self.characterLabel.text = photo.title;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        NSInteger page = scrollView.contentOffset.x/CGRectGetWidth(self.view.bounds);
        FlickrPhoto *photo = self.flickrPhotos[page];
        self.characterLabel.text = photo.title;
    }
}

@end
