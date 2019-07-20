//
//  OAAppDelegate.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAAppDelegate.h"

#import <UIKit/UIKit.h>

#import "OsmAndApp.h"
#import "OsmAndAppPrivateProtocol.h"
#import "OARootViewController.h"
#import "OANavigationController.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAMapRendererView.h"
#import "OALaunchScreenViewController.h"
#import "OAMapLayers.h"
#import "OAPOILayer.h"
#import "OAMapViewState.h"

#include "CoreResourcesFromBundleProvider.h"

#include <QDir>
#include <QFile>

#include <OsmAndCore.h>
#include <OsmAndCore/IncrementalChangesManager.h>
#include <OsmAndCore/Logging.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QIODeviceLogSink.h>
#include <OsmAndCore/FunctorLogSink.h>

#import "OAFirstUsageWelcomeController.h"
#import "Firebase.h"

#define kCheckLiveIntervalHour 3600

@implementation OAAppDelegate
{
    id<OsmAndAppProtocol, OsmAndAppCppProtocol, OsmAndAppPrivateProtocol> _app;
    
    UIBackgroundTaskIdentifier _appInitTask;
    BOOL _coreInitDone;
    BOOL _appInitDone;
    
    NSURL *loadedURL;
    NSTimer *_checkLiveTimer;
}

@synthesize window = _window;
@synthesize rootViewController = _rootViewController;

- (BOOL) initialize
{
    // Configure device
    UIDevice* device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    device.batteryMonitoringEnabled = YES;
    
    // Create instance of OsmAnd application
    _app = (id<OsmAndAppProtocol, OsmAndAppCppProtocol, OsmAndAppPrivateProtocol>)[OsmAndApp instance];
    
    // Create window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[OALaunchScreenViewController alloc] init];
    [self.window makeKeyAndVisible];
    
    _appInitTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"appInitTask" expirationHandler:^{
        
        [[UIApplication sharedApplication] endBackgroundTask:_appInitTask];
        _appInitTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Initialize OsmAnd core
        const std::shared_ptr<CoreResourcesFromBundleProvider> coreResourcesFromBundleProvider(new CoreResourcesFromBundleProvider());
        OsmAnd::InitializeCore(coreResourcesFromBundleProvider);
        _coreInitDone = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Initialize application
            [_app initialize];
            
            // Update app execute counter
            NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
            NSInteger execCount = [settings integerForKey:kAppExecCounter];
            [settings setInteger:++execCount forKey:kAppExecCounter];
            
            if ([settings doubleForKey:kAppInstalledDate] == 0)
                [settings setDouble:[[NSDate date] timeIntervalSince1970] forKey:kAppInstalledDate];
            
            [settings synchronize];
            
            // Create root view controller
            _rootViewController = [[OARootViewController alloc] init];
            self.window.rootViewController = [[OANavigationController alloc] initWithRootViewController:_rootViewController];
            
            BOOL mapInstalled = NO;
            for (const auto& resource : _app.resourcesManager->getLocalResources())
            {
                if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
                {
                    mapInstalled = YES;
                    break;
                }
            }
            // Show intro screen
            if (execCount == 1 || !mapInstalled)
            {
                OAFirstUsageWelcomeController* welcome = [[OAFirstUsageWelcomeController alloc] init];
                [self.rootViewController.navigationController pushViewController:welcome animated:NO];
            }
            
            if (loadedURL)
            {
                [_rootViewController handleIncomingURL:loadedURL];
                loadedURL = nil;
            }
            
            _appInitDone = YES;
            [[UIApplication sharedApplication] endBackgroundTask:_appInitTask];
            _appInitTask = UIBackgroundTaskInvalid;
            
            // Check for updates at the app start
            [_app checkAndDownloadOsmAndLiveUpdates];
            // Set the background fetch
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:kCheckLiveIntervalHour];
            // Check for updates every hour when the app is in the foreground
            _checkLiveTimer = [NSTimer scheduledTimerWithTimeInterval:kCheckLiveIntervalHour target:self selector:@selector(performUpdateCheck) userInfo:nil repeats:YES];
        });
    });
    
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    NSDictionary *params = [OAUtilities parseUrlQuery:userActivity.webpageURL];
    if (params.count != 0){
        // osmandmaps://?lat=45.6313&lon=34.9955&z=8&title=New+York
        double lat = [params[@"lat"] doubleValue];
        double lon = [params[@"lon"] doubleValue];
        double zoom = [params[@"z"] doubleValue];
        NSString *title = params[@"title"];
        NSString *navigate = [userActivity.webpageURL host];
        
        Point31 pos31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon))];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            OAMapViewController* mapViewController = [_rootViewController.mapPanel mapViewController];
            
            if (!_rootViewController || !mapViewController || !mapViewController.isViewLoaded)
            {
                OAMapViewState *state = [[OAMapViewState alloc] init];
                state.target31 = pos31;
                state.zoom = zoom;
                state.azimuth = 0.0f;
                state.elevationAngle = 90.0f;
                _app.initialURLMapState = state;
                return;
            }
            
            UIViewController *top = _rootViewController.navigationController.topViewController;
            
            if (![top isKindOfClass:[JASidePanelController class]])
                [_rootViewController.navigationController popToRootViewControllerAnimated:NO];
            
            if (_rootViewController.state != JASidePanelCenterVisible)
                [_rootViewController showCenterPanelAnimated:NO];
            
            [_rootViewController.mapPanel closeDashboard];
            
            [mapViewController goToPosition:pos31 andZoom:zoom animated:NO];
            OATargetPoint *targetPoint = [mapViewController.mapLayers.contextMenuLayer getUnknownTargetPoint:lat longitude:lon];
            if (title.length > 0)
                targetPoint.title = title;
            if ([navigate  isEqual: @"navigate"]){
                [_rootViewController.mapPanel navigate:targetPoint];
                [_rootViewController.mapPanel closeRouteInfo];
                [_rootViewController.mapPanel startNavigation];
            } else {
                [_rootViewController.mapPanel showContextMenu:targetPoint];
            }
        });
        
        return YES;
    }
    return NO;
}

- (void) performUpdateCheck
{
    [_app checkAndDownloadOsmAndLiveUpdates];
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !defined(OSMAND_IOS_DEV)
    // Use Firebase library to configure APIs
    if (![OAAppSettings sharedManager].settingDoNotUseFirebase)
        [FIRApp configure];
#endif // defined(OSMAND_IOS_DEV)
    if (application.applicationState == UIApplicationStateBackground)
        return NO;
    
    return [self initialize];
}

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSDate *methodStart = [NSDate date];
    if (_app.resourcesManager == nullptr )
    {
        completionHandler(UIBackgroundFetchResultFailed);
        return;
    }
    [_app checkAndDownloadOsmAndLiveUpdates];
    completionHandler(UIBackgroundFetchResultNewData);
    NSDate *methodEnd = [NSDate date];
    NSLog(@"Background fetch took %f sec.", [methodEnd timeIntervalSinceDate:methodStart]);
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{
    completionHandler();
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSString *scheme = [[url scheme] lowercaseString];

    if ([scheme isEqualToString:@"file"])
    {
        if (_rootViewController)
            return [_rootViewController handleIncomingURL:url];
        
        loadedURL = url;
    }
    
    return NO;
}

- (void) applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    if (_appInitDone)
        [_app onApplicationWillResignActive];
}

- (void) applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if (_checkLiveTimer)
    {
        [_checkLiveTimer invalidate];
        _checkLiveTimer = nil;
    }
    if (_appInitDone)
        [_app onApplicationDidEnterBackground];
}

- (void) applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    if (_appInitDone)
        [_app onApplicationWillEnterForeground];
    else
        [self initialize];
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    if (_appInitDone)
    {
        _checkLiveTimer = [NSTimer scheduledTimerWithTimeInterval:kCheckLiveIntervalHour target:self selector:@selector(performUpdateCheck) userInfo:nil repeats:YES];
        [_app onApplicationDidBecomeActive];
    }
}

- (void) applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [_app shutdown];
    
    // Release OsmAnd core
    OsmAnd::ReleaseCore();
    
    // Deconfigure device
    UIDevice* device = [UIDevice currentDevice];
    device.batteryMonitoringEnabled = NO;
    [device endGeneratingDeviceOrientationNotifications];
}

- (void) application:(UIApplication *)application willChangeStatusBarFrame:(CGRect)newStatusBarFrame
{
    [OASharedVariables setStatusBarHeight:newStatusBarFrame.size.height];
}

@end
