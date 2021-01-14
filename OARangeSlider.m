//
//  OARangeSlider.m
//  OsmAnd
//
//  Created by nnngrach on 13.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARangeSlider.h"


@implementation OARangeSlider
{
    NSMutableArray<NSNumber *> *_hostVCGestureRecognizersStateBackup;
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self disableHostVCScroll];
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self restoreHostVCScroll];
    [super endTrackingWithTouch:touch withEvent:event];
}

- (void) disableHostVCScroll
{
    if ([self.delegate isKindOfClass:UIViewController.class])
    {
        UIViewController *hostVC = (UIViewController *)self.delegate;
        NSArray<__kindof UIGestureRecognizer *> *recognizers = hostVC.presentationController.presentedView.gestureRecognizers;
        
        for (int i = 0; i < recognizers.count; i++)
        {
            UIGestureRecognizer *recognizer = recognizers[i];
            [_hostVCGestureRecognizersStateBackup addObject:[NSNumber numberWithBool:recognizer.isEnabled]];
            [recognizer setEnabled:NO];
        }
    }
}

- (void) restoreHostVCScroll
{
    if ([self.delegate isKindOfClass:UIViewController.class])
    {
        UIViewController *hostVC = (UIViewController *)self.delegate;
        NSArray<__kindof UIGestureRecognizer *> *recognizers = hostVC.presentationController.presentedView.gestureRecognizers;
        for (int i = 0; i < recognizers.count; i++)
        {
            UIGestureRecognizer *recognizer = recognizers[i];
            [recognizer setEnabled:_hostVCGestureRecognizersStateBackup[i]];
        }
    }
}

@end
