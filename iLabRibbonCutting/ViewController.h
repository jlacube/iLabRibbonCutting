//
//  ViewController.h
//  iLabRibbonCutting
//
//  Created by Jerome LACUBE on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerView.h"

static const NSString *ItemStatusContext; // used for synchronization

@interface ViewController : UIViewController
{
    BOOL pageCurl;
    BOOL slide;
    BOOL externalScreen;
    BOOL airPlay;
}

- (void)layout;
- (void)layoutWithOrientation:(UIInterfaceOrientation)orientation;

@property (nonatomic,strong) UIWindow *externalWindow;
@property (nonatomic,strong) PlayerView *externalView;
@property (nonatomic,strong) UIImageView *extLeftView;
@property (nonatomic,strong) UIImageView *extRightView;
@property (nonatomic,strong) AVPlayerItem *extPlayerItem;
@property (nonatomic,strong) AVPlayer *extPlayer;

@property (nonatomic,strong) AVPlayerItem *playerItem;
@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) UIImageView *leftView;
@property (nonatomic,strong) UIImageView *rightView;

@end
