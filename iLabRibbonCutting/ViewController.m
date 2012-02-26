//
//  ViewController.m
//  iLabRibbonCutting
//
//  Created by Jerome LACUBE on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

@synthesize externalWindow;
@synthesize  externalView;
@synthesize extLeftView;
@synthesize extRightView;
@synthesize extPlayer;
@synthesize extPlayerItem;

@synthesize leftView;
@synthesize rightView;
@synthesize player;
@synthesize playerItem;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self layout];
}

- (void)layout
{
    [self layoutWithOrientation:self.interfaceOrientation];
}

- (void)layoutWithOrientation:(UIInterfaceOrientation)orientation
{
    airPlay = [[NSUserDefaults standardUserDefaults] boolForKey:@"airplay"];
    pageCurl = NO;
    slide = NO;
    switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"anim"]) {
        case 0:
            pageCurl = YES;
            break;
        case 1:
            slide = YES;
            break;
        case 2:
            pageCurl = YES;
            slide = YES;
            break;
            
        default:
            break;
    }
    
    CGFloat imageWidth = 0;
    CGFloat imageHeight = 0;
    
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
    {
        imageWidth = self.view.frame.size.height / 2;
        imageHeight = self.view.frame.size.width;
    }
    else
    {
        imageWidth = self.view.frame.size.width / 2;
        imageHeight = self.view.frame.size.height;
    }
    
    CGRect leftRect = CGRectMake(0, 0, imageWidth, imageHeight);
    CGRect rightRect = CGRectMake(imageWidth, 0, imageWidth, imageHeight);
    
    if (leftView == nil)
    {
        leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iLabLeftRibbon"]];
        [self.view addSubview:leftView];
        leftView.userInteractionEnabled = YES;
        
        UISwipeGestureRecognizer *leftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
        leftGesture.direction = UISwipeGestureRecognizerDirectionDown | UISwipeGestureRecognizerDirectionUp;
        leftGesture.numberOfTouchesRequired = 1;
        [leftView addGestureRecognizer:leftGesture];
    }
    leftView.frame = leftRect;
    
    if (rightView == nil)
    {
        rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iLabRightRibbon"]];
        [self.view addSubview:rightView];
        rightView.userInteractionEnabled = YES;
        
        UISwipeGestureRecognizer *rightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeAction:)];
        rightGesture.direction = UISwipeGestureRecognizerDirectionDown | UISwipeGestureRecognizerDirectionUp;
        rightGesture.numberOfTouchesRequired = 1;
        [rightView addGestureRecognizer:rightGesture];
    }
    rightView.frame = rightRect;
    
    UIScreen *lastScreen = [[UIScreen screens] lastObject];
    
    if (lastScreen != self.view.window.screen && [[UIScreen screens] count] > 1)
    {
        externalScreen = YES;
        lastScreen.currentMode = [lastScreen.availableModes lastObject];
        
        // We have an external screen to handle
        externalWindow = [[UIWindow alloc] initWithFrame:lastScreen.applicationFrame];
        externalWindow.screen = lastScreen;
        externalWindow.hidden = NO;
        externalWindow.clipsToBounds = YES;
        [externalWindow makeKeyAndVisible];
        
        externalView = [[PlayerView alloc] initWithFrame:externalWindow.bounds];
        externalView.backgroundColor = [UIColor blackColor];
        
        [externalWindow addSubview:externalView];
        
        extLeftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iLabLeftRibbon"]];
        [externalView addSubview:extLeftView];
        extLeftView.frame = CGRectMake(0, 0, lastScreen.bounds.size.width / 2, lastScreen.bounds.size.height);
        
        extRightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iLabRightRibbon"]];
        [externalView addSubview:extRightView];
        extRightView.frame = CGRectMake(lastScreen.bounds.size.width / 2, 0, lastScreen.bounds.size.width / 2, lastScreen.bounds.size.height);
    }
    else
    {
        externalScreen = NO;
    }
    
    NSURL *fileURL = [[NSBundle mainBundle]
                      URLForResource:@"Fireworks" withExtension:@"m4v"];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    NSString *tracksKey = @"tracks";
    
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    
    // Mute all the audio tracks
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =[AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:0.0 atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioZeroMix = [AVMutableAudioMix audioMix];
    [audioZeroMix setInputParameters:allAudioParams];
    
    [asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:tracksKey] completionHandler:
     ^{
         // Define this constant for the key-value observation context.
         
         // Completion handler block.
         dispatch_async(dispatch_get_main_queue(),
                        ^{
                            NSError *error = nil;
                            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
                            
                            if (status == AVKeyValueStatusLoaded) {
                                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                                [playerItem addObserver:self forKeyPath:@"status"
                                                options:0 context:&ItemStatusContext];
                                [[NSNotificationCenter defaultCenter] addObserver:self
                                                                         selector:@selector(playerItemDidReachEnd:)
                                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                                           object:playerItem];
                                self.player = [AVPlayer playerWithPlayerItem:playerItem];
                                [((PlayerView*)self.view) setPlayer:player];
                                
//                                if (!airPlay)
//                                {
                                    self.extPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
                                    [extPlayerItem setAudioMix:audioZeroMix];
                                    [extPlayerItem addObserver:self
                                                forKeyPath:@"status"
                                                   options:0
                                                   context:&ItemStatusContext];
                                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                                         selector:@selector(extPlayerItemDidReachEnd:)
                                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                                           object:extPlayerItem];
                                    self.extPlayer = [AVPlayer playerWithPlayerItem:extPlayerItem];
                                    [externalView setPlayer:extPlayer];
//                                }
                            }
                            else {
                                // You should deal with the error appropriately.
                                NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                            }
                        });
     }];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    // add fade out to BackScreen
    UIImageView *backView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BackScreen.jpg"]];
    backView.alpha = 0.0;
    backView.frame = self.view.bounds;
    [self.view addSubview:backView];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [backView setAlpha:1.0];
    [UIView commitAnimations];
}

- (void)extPlayerItemDidReachEnd:(NSNotification *)notification {
    // add fade out to BackScreen
    UIImageView *extBackView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BackScreen.jpg"]];
    extBackView.alpha = 0.0;
    extBackView.frame = externalView.bounds;
    [externalView addSubview:extBackView];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [extBackView setAlpha:1.0];
    [UIView commitAnimations];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           // [self syncUI];
                       });
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}


-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)io
                                        duration:(NSTimeInterval)duration {
    [self layoutWithOrientation:io];
}

- (void)swipeAction:(id)sender
{
    [player play];
    [extPlayer play];
    
    // mainScreen
    [UIView transitionWithView:leftView
                      duration:(pageCurl && slide ? 5 : 2)
                       options:(pageCurl ? UIViewAnimationOptionTransitionCurlUp : UIViewAnimationOptionTransitionNone)
                    animations:^{
                        if (pageCurl)
                            leftView.hidden = YES;
                        if (slide)
                            leftView.frame = CGRectMake(-512, 0, 10, 768);
                    }
                    completion:^(BOOL finished){}];
    
    [UIView transitionWithView:rightView
                      duration:(pageCurl && slide ? 5 : 2)
                       options:(pageCurl ? UIViewAnimationOptionTransitionCurlUp : UIViewAnimationOptionTransitionNone)
                    animations:^{
                        if (pageCurl)
                            rightView.hidden = YES;
                        if (slide)
                            rightView.frame = CGRectMake(1536, 0, 10, 768);
                    }
                    completion:^(BOOL finished){}];
    
    // externalScreen
    if (externalScreen)
    {
        [UIView transitionWithView:extLeftView
                          duration:2
                           options:(pageCurl ? UIViewAnimationOptionTransitionCurlUp : UIViewAnimationOptionTransitionNone)
                        animations:^{
                            if (pageCurl)
                                extLeftView.hidden = YES;
                            if (slide)
                                extLeftView.frame = CGRectMake(-512, 0, 10, 768);
                        }
                        completion:^(BOOL finished){}];
        
        [UIView transitionWithView:extRightView
                          duration:2
                           options:(pageCurl ? UIViewAnimationOptionTransitionCurlUp : UIViewAnimationOptionTransitionNone)
                        animations:^{
                            if (pageCurl)
                                extRightView.hidden = YES;
                            if (slide)
                                extRightView.frame = CGRectMake(1536, 0, 10, 768);
                        }
                        completion:^(BOOL finished){}];

    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
