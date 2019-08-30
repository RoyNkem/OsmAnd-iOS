//
//  OASavingTrackHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAGPXMutableDocument;
@class OAGPX;
@class OAGpxWpt;

@interface OASavingTrackHelper : NSObject

@property (nonatomic, readonly) long lastTimeUpdated;
@property (nonatomic, readonly) int points;
@property (nonatomic, readonly) float distance;
@property (nonatomic, readonly) BOOL isRecording;

@property (nonatomic, readonly) OAGPXMutableDocument *currentTrack;

+ (OASavingTrackHelper *)sharedInstance;

- (OAGPX *)getCurrentGPX;

- (BOOL) hasData;
- (BOOL) hasDataToSave;
- (void) clearData;
- (void) saveDataToGpx;
- (void) startNewSegment;
- (BOOL) saveCurrentTrack:(NSString *)fileName;

- (BOOL) saveIfNeeded;

- (void)addWpt:(OAGpxWpt *)wpt;
- (void)deleteWpt:(OAGpxWpt *)wpt;
- (void)deleteAllWpts;
- (void)saveWpt:(OAGpxWpt *)wpt;

- (BOOL) getIsRecording;

- (void) runSyncBlock:(void (^)(void))block;

@end
