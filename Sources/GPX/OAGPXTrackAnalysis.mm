//
//  OAGPXTrackAnalysis.m
//  OsmAnd
//
//  Created by Alexey Kulish on 13/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXTrackAnalysis.h"
#import "OAGPXDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OALocationServices.h"

#include <OsmAndCore/Utilities.h>


@implementation OASplitMetric

-(double) metric:(OAGpxWpt*)p1 p2:(OAGpxWpt*)p2 { return 0; };

@end


@implementation OADistanceMetric

-(double) metric:(OAGpxWpt*)p1 p2:(OAGpxWpt*)p2
{
    CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:p1.position.latitude longitude:p1.position.longitude];
    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:p2.position.latitude longitude:p2.position.longitude];
    return [loc1 distanceFromLocation:loc2];
}

@end


@implementation OATimeSplit

-(double) metric:(OALocationMark *)p1 p2:(OALocationMark *)p2
{
    if(p1.time != 0 && p2.time != 0) {
        return abs((p2.time - p1.time) / 1000l);
    }
    return 0;
}

@end

@implementation OAElevation

- (instancetype)init
{
    self = [super init];
    if (self) {
        _firstPoint = NO;
        _lastPoint = NO;
    }
    return self;
}

@end

@implementation OASpeed

- (instancetype)init
{
    self = [super init];
    if (self) {
        _firstPoint = NO;
        _lastPoint = NO;
    }
    return self;
}

@end

@implementation OASplitSegment

- (instancetype)initWithTrackSegment:(OAGpxTrkSeg *)s
{
    self = [super init];
    if (self) {
        _startPointInd = 0;
        _startCoeff = 0;
        _endPointInd = (int)s.points.count - 2;
        _endCoeff = 1;
        self.segment = s;
    }
    return self;
}

- (instancetype)initWithSplitSegment:(OAGpxTrkSeg *)s pointInd:(int)pointInd cf:(double)cf
{
    self = [super init];
    if (self) {
        _startPointInd = 0;
        _startCoeff = 0;
        _startPointInd = pointInd;
        _startCoeff = cf;
        self.segment = s;
    }
    return self;
}

-(int) getNumberOfPoints
{
    return _endPointInd - _startPointInd + 2;
}

-(OALocationMark *) get:(int)j
{
    int ind = j + _startPointInd;
    if(j == 0) {
        if(_startCoeff == 0) {
            return [self.segment.points objectAtIndex:ind];
        }
         return [self approx:[self.segment.points objectAtIndex:ind] w2:[self.segment.points objectAtIndex:ind + 1] cf:_startCoeff];
    }
    if(j == [self getNumberOfPoints] - 1) {
        if(_endCoeff == 1) {
            return [self.segment.points objectAtIndex:ind];
        }
        return [self approx:[self.segment.points objectAtIndex:ind - 1] w2:[self.segment.points objectAtIndex:ind] cf:_endCoeff];
    }
    return [self.segment.points objectAtIndex:ind];
}


-(OAGpxWpt *) approx:(OAGpxTrkPt *)w1 w2:(OAGpxTrkPt *)w2 cf:(double)cf
{
    long time = [self valueLong:w1.time vl2:w2.time none:0 cf:cf];
    double speed = [self valueDbl:w1.speed vl2:w2.speed none:0 cf:cf];
    double ele = [self valueDbl:w1.elevation vl2:w2.elevation none:0 cf:cf];
    double hdop = [self valueDbl:w1.horizontalDilutionOfPrecision vl2:w2.horizontalDilutionOfPrecision none:0 cf:cf];
    double lat = [self valueDbl:w1.position.latitude vl2:w2.position.latitude none:-360 cf:cf];
    double lon = [self valueDbl:w1.position.longitude vl2:w2.position.longitude none:-360 cf:cf];
    
    OAGpxWpt *wpt = [[OAGpxWpt alloc] init];
    wpt.position = CLLocationCoordinate2DMake(lat, lon);
    wpt.time = time;
    wpt.elevation = ele;
    wpt.speed = speed;
    wpt.horizontalDilutionOfPrecision = hdop;
    
    return wpt;
}

-(double) valueDbl:(double)vl vl2:(double)vl2 none:(double)none cf:(double)cf
{
    if (vl == none || isnan(vl)) {
        return vl2;
    } else if (vl2 == none || isnan(vl2)) {
        return vl;
    }
    return vl + cf * (vl2 - vl);
}

-(long) valueLong:(long)vl vl2:(long)vl2 none:(long)none cf:(double)cf
{
    if(vl == none) {
        return vl2;
    } else if(vl2 == none) {
        return vl;
    }
    return vl + ((long) (cf * (vl2 - vl)));
}

-(double) setLastPoint:(int)pointInd endCf:(double)endCf
{
    _endCoeff = endCf;
    _endPointInd = pointInd;
    return _endCoeff;
}

@end

@implementation OAGPXTrackAnalysis

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _totalDistance = 0.0;
        _totalTracks = 0;
        _startTime = LONG_MAX;
        _endTime = LONG_MIN;
        _timeSpan = 0;
        _timeMoving = 0;
        _totalDistanceMoving = 0.0;
        
        _diffElevationUp = 0.0;
        _diffElevationDown = 0.0;
        _avgElevation = 0.0;
        _minElevation = 99999.0;
        _maxElevation = -100.0;
        _timeSpanWithoutGaps = 0;
        _totalDistanceWithoutGaps = 0.0;
        _timeMovingWithoutGaps = 0.0;
        _totalDistanceMovingWithoutGaps = 0.0;
        _left = 0;
        _right = 0;
        _bottom = 0;
        _top = 0;
        
        _maxSpeed = 0.0;
        _minSpeed = FLT_MAX;
        
        _wptPoints = 0;
        
    }
    return self;
}
 
-(BOOL) isTimeSpecified
{
    return _startTime != LONG_MAX && _startTime != 0;
}

-(BOOL) isTimeMoving
{
    return _timeMoving != 0;
}

-(BOOL) isElevationSpecified
{
    return _maxElevation != -100;
}

-(int) getTimeHours:(long)time
{
    return (int) ((time / 1000) / 3600);
}


-(int) getTimeSeconds:(long)time
{
    return (int) ((time / 1000) % 60);
}

-(int) getTimeMinutes:(long)time
{
    return (int) (((time / 1000) / 60) % 60);
}

-(BOOL) isSpeedSpecified
{
    return _avgSpeed > 0.0;
}

+(OAGPXTrackAnalysis *) segment:(long)fileTimestamp seg:(OAGpxTrkSeg *)seg
{
    OAGPXTrackAnalysis *obj = [[OAGPXTrackAnalysis alloc] init];
    [obj prepareInformation:fileTimestamp splitSegments:@[[[OASplitSegment alloc] initWithTrackSegment:seg]]];
    return obj;
}

-(void) prepareInformation:(long)fileStamp  splitSegments:(NSArray *)splitSegments
{
    long startTimeOfSingleSegment = 0;
    long endTimeOfSingleSegment = 0;
    
    float distanceOfSingleSegment = 0;
    float distanceMovingOfSingleSegment = 0;
    long timeMovingOfSingleSegment = 0;
    
    float totalElevation = 0;
    NSInteger elevationPoints = 0;
    NSInteger speedCount = 0;
    NSInteger timeDiff = 0;
    double totalSpeedSum = 0;
    _points = 0;
    
    double channelThresMin = 10; // Minimum oscillation amplitude considered as relevant or as above noise for accumulated Ascent/Descent analysis
    double channelThres = channelThresMin; // Actual oscillation amplitude considered as above noise (dynamic channel adjustment, accomodates depedency on current VDOP/getAccuracy if desired)
    double channelBase;
    double channelTop;
    double channelBottom;
    BOOL climb = NO;
    
    NSMutableArray<OAElevation *> *elevationData = [NSMutableArray new];
    NSMutableArray<OASpeed *> *speedData = [NSMutableArray new];
    
    for (OASplitSegment *s in splitSegments)
    {
        int numberOfPoints = s.getNumberOfPoints;
        
        channelBase = 99999;
        channelTop = channelBase;
        channelBottom = channelBase;
        //channelThres = channelThresMin; //only for dynamic channel adjustment
        
        float segmentDistance = 0.;
        _metricEnd += s.metricEnd;
        _secondaryMetricEnd += s.secondaryMetricEnd;
        _points += numberOfPoints;
        for (NSInteger j = 0; j < numberOfPoints; j++)
        {
            OAGpxWpt *point = (OAGpxWpt *) [s get:j];
            if (j == 0 && self.locationStart == nil)
                _locationStart = point;
            if (j == numberOfPoints - 1)
                _locationEnd = point;

            long time = point.time;
            if (time != 0)
            {
                if (s.metricEnd == 0)
                {
                    if (s.segment.generalSegment)
                    {
                        if (point.firstPoint)
                            startTimeOfSingleSegment = time;
                        else if (point.lastPoint)
                            endTimeOfSingleSegment = time;
                        
                        if (startTimeOfSingleSegment != 0 && endTimeOfSingleSegment != 0)
                        {
                            _timeSpanWithoutGaps += endTimeOfSingleSegment - startTimeOfSingleSegment;
                            startTimeOfSingleSegment = 0;
                            endTimeOfSingleSegment = 0;
                        }
                    }
                }
                _startTime = MIN(_startTime, time);
                _endTime = MAX(_endTime, time);
            }
            
            if (_left == 0 && _right == 0)
            {
                _left = point.getLongitude;
                _right = point.getLongitude;
                _top = point.getLatitude;
                _bottom = point.getLatitude;
            }
            else
            {
                _left = MIN(_left, point.getLongitude);
                _right = MAX(_right, point.getLongitude);
                _top = MAX(_top, point.getLatitude);
                _bottom = MIN(_bottom, point.getLatitude);
            }
            
            CLLocationDistance elevation = point.elevation;
            OAElevation *elevation1 = [[OAElevation alloc] init];
            if (!isnan(elevation))
            {
                totalElevation += elevation;
                elevationPoints++;
                _minElevation = MIN(elevation, _minElevation);
                _maxElevation = MAX(elevation, _maxElevation);
                
                elevation1.elevation = elevation;
            }
            else
            {
                elevation1.elevation = NAN;
            }
            
            CLLocationSpeed speed = point.speed;
            if (speed > 0)
                _hasSpeedInTrack = YES;
            
            // Trend channel analysis for elevation gain/loss, Hardy 2015-09-22, LPF filtering added 2017-10-26:
            // - Detect the consecutive elevation trend channels: Only use the net elevation changes of each trend channel (i.e. between the turnarounds) to accumulate the Ascent/Descent values.
            // - Perform the channel evaluation on Low Pass Filter (LPF) smoothed ele data instead of on the raw ele data
            // Parameters:
            // - channelThresMin (in meters): defines the channel turnaround detection, i.e. oscillations smaller than this are ignored as irrelevant or noise.
            // - smoothWindow (number of points): is the LPF window
            // NOW REMOVED, as no relevant examples found: Dynamic channel adjustment: To suppress unreliable measurement points, could relax the turnaround detection from the constant channelThresMin to channelThres which is e.g. based on the maximum VDOP of any point which contributed to the current trend. (Good assumption is VDOP=2*HDOP, which accounts for invisibility of lower hemisphere satellites.)
            
            // LPF smooting of ele data, usually smooth over odd number of values like 5
            NSInteger smoothWindow = 5;
            double eleSmoothed = NAN;
            NSInteger j2 = 0;
            for (NSInteger j1 = - smoothWindow + 1; j1 <= 0; j1++)
            {
                if ((j + j1 >= 0) && !isnan([s get:j + j1].elevation))
                {
                    j2++;
                    if (!isnan(eleSmoothed))
                        eleSmoothed = eleSmoothed + [s get:j + j1].elevation;
                    else
                        eleSmoothed = [s get:j + j1].elevation;
                }
            }
            if (!isnan(eleSmoothed))
                eleSmoothed = eleSmoothed / j2;
            
            if (!isnan(eleSmoothed))
            {
                // Init channel
                if (channelBase == 99999)
                {
                    channelBase = eleSmoothed;
                    channelTop = channelBase;
                    channelBottom = channelBase;
                    //channelThres = channelThresMin; //only for dynamic channel adjustment
                }
                // Channel maintenance
                if (eleSmoothed > channelTop)
                {
                    channelTop = eleSmoothed;
                    //if (!Double.isNaN(point.hdop)) {
                    //    channelThres = Math.max(channelThres, 2.0 * point.hdop); //only for dynamic channel adjustment
                    //}
                }
                else if (eleSmoothed < channelBottom)
                {
                    channelBottom = eleSmoothed;
                    //if (!Double.isNaN(point.hdop)) {
                    //    channelThres = Math.max(channelThres, 2.0 * point.hdop); //only for dynamic channel adjustment
                    //}
                }
                // Turnaround (breakout) detection
                if ((eleSmoothed <= (channelTop - channelThres)) && (climb == YES))
                {
                    if ((channelTop - channelBase) >= channelThres)
                        _diffElevationUp += channelTop - channelBase;

                    channelBase = channelTop;
                    channelBottom = eleSmoothed;
                    climb = false;
                    //channelThres = channelThresMin; //only for dynamic channel adjustment
                }
                else if ((eleSmoothed >= (channelBottom + channelThres)) && (climb == NO))
                {
                    if ((channelBase - channelBottom) >= channelThres)
                        _diffElevationDown += channelBase - channelBottom;

                    channelBase = channelBottom;
                    channelTop = eleSmoothed;
                    climb = true;
                    //channelThres = channelThresMin; //only for dynamic channel adjustment
                }
                // End detection without breakout
                if (j == (numberOfPoints - 1))
                {
                    if ((channelTop - channelBase) >= channelThres)
                    {
                        _diffElevationUp += channelTop - channelBase;
                    }
                    if ((channelBase - channelBottom) >= channelThres)
                    {
                        _diffElevationDown += channelBase - channelBottom;
                    }
                }
            }
            // float[1] calculations
            double distance = 0, bearing = 0;
            if (j > 0) {
                OAGpxWpt *prev = (OAGpxWpt *)[s get:j - 1];
                
                // Old complete summation approach for elevation gain/loss
                //if (!Double.isNaN(point.ele) && !Double.isNaN(prev.ele)) {
                //    double diff = point.ele - prev.ele;
                //    if (diff > 0) {
                //        diffElevationUp += diff;
                //    } else {
                //        diffElevationDown -= diff;
                //    }
                //}
                
                // totalDistance += MapUtils.getDistance(prev.lat, prev.lon, point.lat, point.lon);
                // using ellipsoidal 'distanceBetween' instead of spherical haversine (MapUtils.getDistance) is
                // a little more exact, also seems slightly faster:
                [OALocationServices computeDistanceAndBearing:prev.getLatitude lon1:prev.getLongitude lat2:point.getLatitude lon2:point.getLongitude distance:&distance initialBearing:&bearing];
                _totalDistance += distance;
                segmentDistance += distance;
                point.distance = segmentDistance;
                timeDiff = (NSInteger)((point.time - prev.time));
                
                //Last resort: Derive speed values from displacement if track does not originally contain speed
                if (!_hasSpeedInTrack && speed == 0 && timeDiff > 0)
                    speed = distance / timeDiff;
                
                // Motion detection:
                //   speed > 0  uses GPS chipset's motion detection
                //   calculations[0] > minDisplacment * time  is heuristic needed because tracks may be filtered at recording time, so points at rest may not be present in file at all
                if ((speed > 0) && (distance > 0.1 / 1000 * ((point.time - prev.time) * 1000)) && point.time != 0 && prev.time != 0)
                {
                    _timeMoving += (point.time - prev.time);
                    _totalDistanceMoving += distance;
                    if (s.segment.generalSegment && !point.firstPoint)
                    {
                        timeMovingOfSingleSegment += point.time - prev.time;
                        distanceMovingOfSingleSegment += distance;
                    }
                }
                
                //Next few lines for Issue 3222 heuristic testing only
                //    if (speed > 0 && point.time != 0 && prev.time != 0) {
                //        timeMoving0 = timeMoving0 + (point.time - prev.time);
                //        totalDistanceMoving0 += calculations[0];
                //    }
            }
            
            elevation1.time = timeDiff;
            elevation1.distance = (j > 0) ? distance : 0;
            [elevationData addObject:elevation1];
            if (!_hasElevationData && !isnan(elevation1.elevation) && _totalDistance > 0)
                _hasElevationData = YES;
            
            _minSpeed = MIN(speed, _minSpeed);
            if (speed > 0)
            {
                totalSpeedSum += speed;
                _maxSpeed = MAX(speed, _maxSpeed);
                speedCount++;
            }
            
            OASpeed *speed1 = [[OASpeed alloc] init];
            speed1.speed = speed;
            speed1.time = timeDiff;
            speed1.distance = elevation1.distance;
            [speedData addObject:speed1];
            if (!_hasSpeedData && speed1.speed > 0 && _totalDistance > 0)
                _hasSpeedData = YES;
            
            if (s.segment.generalSegment)
            {
                distanceOfSingleSegment += distance;
                if (point.firstPoint)
                {
                    distanceOfSingleSegment = 0;
                    timeMovingOfSingleSegment = 0;
                    distanceMovingOfSingleSegment = 0;
                    if (j > 0)
                    {
                        elevation1.firstPoint = YES;
                        speed1.firstPoint = YES;
                    }
                }
                if (point.lastPoint)
                {
                    _totalDistanceWithoutGaps += distanceOfSingleSegment;
                    _timeMovingWithoutGaps += timeMovingOfSingleSegment;
                    _totalDistanceMovingWithoutGaps += distanceMovingOfSingleSegment;
                    if (j < numberOfPoints - 1)
                    {
                        elevation1.lastPoint = true;
                        speed1.lastPoint = true;
                    }
                }
            }
        }
    }
    if (_totalDistance < 0) {
        _hasElevationData = NO;
        _hasSpeedData = NO;
    }
    if (![self isTimeSpecified])
    {
        _startTime = fileStamp;
        _endTime = fileStamp;
    }
    
    // OUTPUT:
    // 1. Total distance, Start time, End time
    // 2. Time span
    if (_timeSpan == 0) {
        _timeSpan = _endTime - _startTime;
    }
    
    // 3. Time moving, if any
    // 4. Elevation, eleUp, eleDown, if recorded
    if (elevationPoints > 0)
        _avgElevation = totalElevation / elevationPoints;
    
    // 5. Max speed and Average speed, if any. Average speed is NOT overall (effective) speed, but only calculated for "moving" periods.
    //    Averaging speed values is less precise than totalDistanceMoving/timeMoving
    if (speedCount > 0)
    {
        if (_timeMoving > 0)
            _avgSpeed = ((float) _totalDistanceMoving / (float) _timeMoving);
        else
            _avgSpeed = (float) totalSpeedSum / (float) speedCount;
    }
    else
    {
        _avgSpeed = -1;
    }
    _elevationData = [NSArray arrayWithArray:elevationData];
    _speedData = [NSArray arrayWithArray:speedData];
}

+(void) splitSegment:(OASplitMetric*)metric secondaryMetric:(OASplitMetric *)secondaryMetric metricLimit:(double)metricLimit splitSegments:(NSMutableArray*)splitSegments
             segment:(OAGpxTrkSeg*)segment
{
    double currentMetricEnd = metricLimit;
    double secondaryMetricEnd = 0;
    OASplitSegment *sp = [[OASplitSegment alloc] initWithSplitSegment:segment pointInd:0 cf:0];
    double total = 0;
    OALocationMark *prev = nil;
    for (int k = 0; k < segment.points.count; k++) {
        OALocationMark *point = [segment.points objectAtIndex:k];
        if (k > 0) {
            double currentSegment = [metric metric:prev p2:point];
            secondaryMetricEnd += [secondaryMetric metric:prev p2:point];
            while (total + currentSegment > currentMetricEnd) {
                double p = currentMetricEnd - total;
                double cf = (p / currentSegment);
                [sp setLastPoint:k - 1 endCf:cf];
                sp.metricEnd = currentMetricEnd;
                sp.secondaryMetricEnd = secondaryMetricEnd;
                [splitSegments addObject:sp];
                
                sp = [[OASplitSegment alloc] initWithSplitSegment:segment pointInd:k-1 cf:cf];
                currentMetricEnd += metricLimit;
                prev = [sp get:0];
            }
            total += currentSegment;
        }
        prev = point;
    }
    if (segment.points.count > 0
        && !(sp.endPointInd == segment.points.count - 1 && sp.startCoeff == 1)) {
        sp.metricEnd = total;
        sp.secondaryMetricEnd = secondaryMetricEnd;
        [sp setLastPoint:(int)segment.points.count - 2 endCf:1.0];
        [splitSegments addObject:(sp)];
    }
}

+(NSArray*) convert:(NSArray*)splitSegments
{
    NSMutableArray *ls = [NSMutableArray array];
    for(OASplitSegment *s : splitSegments) {
        OAGPXTrackAnalysis *a = [[OAGPXTrackAnalysis alloc] init];
        [a prepareInformation:0 splitSegments:@[s]];
        [ls addObject:a];
    }
    return ls;
}


@end
