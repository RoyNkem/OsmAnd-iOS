//
//  OATargetMenuViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "OATargetPoint.h"

typedef NS_ENUM(NSInteger, ETopToolbarType)
{
    ETopToolbarTypeFixed = 0,
    ETopToolbarTypeMiddleFixed,
    ETopToolbarTypeFloating,
};

typedef void (^ContentHeightChangeListenerBlock)(CGFloat newHeight);

@protocol OATargetMenuViewControllerDelegate <NSObject>

@optional

- (void) contentHeightChanged:(CGFloat)newHeight;
- (void) contentChanged;

- (void) btnOkPressed;
- (void) btnCancelPressed;
- (void) btnDeletePressed;

- (void) addWaypoint;

- (void) requestHeaderOnlyMode;
- (void) requestFullScreenMode;
- (void) requestFullMode;

- (CGFloat) getVisibleHeight;

- (BOOL) isInFullMode;
- (BOOL) isInFullScreenMode;

- (NSString *) getTargetTitle;

- (void) keyboardWasShown:(CGFloat)keyboardHeight;
- (void) keyboardWasHidden:(CGFloat)keyboardHeight;

- (void) setDownloadProgress:(float)progress text:(NSString *)text;
- (void) showProgressBar;
- (void) hideProgressBar;

-(void) openRouteSettings;

@end

@interface OATargetMenuViewControllerState : NSObject

@end

@interface OATargetMenuControlButton : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) BOOL disabled;

@end

@class OATargetPoint, OATransportStopRoute;

@interface OATargetMenuViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIButton *buttonBack;

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UIView *navBarBackground;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *titleGradient;
@property (weak, nonatomic) IBOutlet UIButton *buttonCancel;
@property (weak, nonatomic) IBOutlet UIButton *buttonOK;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *bottomToolBarView;

@property (nonatomic) UINavigationController* navController;

@property (nonatomic, readonly) BOOL editing;
@property (nonatomic, readonly) BOOL wasEdited;
@property (nonatomic, readonly) BOOL showingKeyboard;
@property (nonatomic, readonly) CGSize keyboardSize;

@property (nonatomic) ETopToolbarType topToolbarType;
@property (nonatomic, readonly) BOOL topToolbarGradient;

@property (nonatomic, readonly) BOOL actionButtonPressed;

@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, readonly) NSString *formattedCoords;

@property (nonatomic) OATargetMenuControlButton *leftControlButton;
@property (nonatomic) OATargetMenuControlButton *rightControlButton;
@property (nonatomic) OATargetMenuControlButton *downloadControlButton;

@property (nonatomic) NSArray<OATransportStopRoute *> *routes;

@property (weak, nonatomic) id<OATargetMenuViewControllerDelegate> delegate;

+ (OATargetMenuViewController *) createMenuController:(OATargetPoint *)targetPoint activeTargetType:(OATargetPointType)activeTargetType activeViewControllerState:(OATargetMenuViewControllerState *)activeViewControllerState;

- (id) getTargetObj;

- (UIImage *) getIcon;

- (BOOL) needAddress;
- (NSString *) getTypeStr;
- (NSString *) getCommonTypeStr;
- (NSAttributedString *) getAttributedTypeStr;
- (NSAttributedString *) getAttributedCommonTypeStr;

- (NSAttributedString *) getAttributedTypeStr:(NSString *)group;

- (UIColor *) getAdditionalInfoColor;
- (NSAttributedString *) getAdditionalInfoStr;
- (UIImage *) getAdditionalInfoImage;

- (BOOL) supportFullMenu;
- (BOOL) supportFullScreen;

- (void) goHeaderOnly;
- (void) goFull;
- (void) goFullScreen;

- (BOOL) showTopControls;
- (BOOL) supportMapInteraction;
- (BOOL) showNearestWiki;

- (BOOL) hasTopToolbar;
- (BOOL) hasBottomToolbar;
- (BOOL) shouldShowToolbar;
- (BOOL) hasTopToolbarShadow;
- (void) applyTopToolbarTargetTitle;
- (void) setTopToolbarAlpha:(CGFloat)alpha;
- (void) setMiddleToolbarAlpha:(CGFloat)alpha;

- (BOOL) needsLayoutOnModeChange;

- (void) applyGradient:(BOOL)gradient alpha:(CGFloat)alpha;

- (BOOL) disablePanWhileEditing;
- (BOOL) supportEditing;
- (void) activateEditing;
- (BOOL) commitChangesAndExit;
- (BOOL) preHide;

- (void) backPressed;
- (void) okPressed;
- (void) cancelPressed;

- (BOOL) hasContent;
- (CGFloat) contentHeight;
- (CGFloat) contentHeight:(CGFloat)width;
- (CGFloat) additionalContentOffset;
- (void) setContentBackgroundColor:(UIColor *)color;
- (void) refreshContent;

- (BOOL) hasInfoView;
- (BOOL) hasInfoButton;
- (BOOL) hasRouteButton;

- (BOOL) hasControlButtons;
- (void) leftControlButtonPressed;
- (void) rightControlButtonPressed;
- (void) downloadControlButtonPressed;

- (void) onMenuSwipedOff;
- (void) onMenuDismissed;

- (void) setupToolBarButtonsWithWidth:(CGFloat)width;

- (OATargetMenuViewControllerState *) getCurrentState;

- (BOOL) isLandscape;

- (NSArray<OATransportStopRoute *> *) getSubTransportStopRoutes:(BOOL)nearby;
- (NSArray<OATransportStopRoute *> *) getLocalTransportStopRoutes;
- (NSArray<OATransportStopRoute *> *) getNearbyTransportStopRoutes;

- (void) requestMapDownloadInfo:(CLLocationCoordinate2D) coordinate;

@end

