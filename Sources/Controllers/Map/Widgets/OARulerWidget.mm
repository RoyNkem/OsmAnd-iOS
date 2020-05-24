//
//  OARulerWidget.m
//  OsmAnd
//
//  Created by Paul on 10/5/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARulerWidget.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OALocationServices.h"
#import "OAUtilities.h"
#import "OAMapUtils.h"
#import "OATextInfoWidget.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapWidgetRegInfo.h"
#import "OAFingerRulerDelegate.h"

#include <OsmAndCore/Utilities.h>

#define kMapRulerMaxWidth 120
#define DRAW_TIME 2
#define LABEL_OFFSET 15
#define CIRCLE_ANGLE_STEP 5
#define TITLE_PADDING 2

@interface OARulerWidget ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation OARulerWidget
{
    OALocationServices *_locationProvider;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapViewController *_mapViewController;
    double _radius;
    double _maxRadius;
    float _cachedViewportScale;
    CGFloat _cachedWidth;
    CGFloat _cachedHeight;
    float _cachedMapElevation;
    float _cachedMapAzimuth;
    float _cachedMapZoom;
    double _mapScale;
    double _mapScaleUnrounded;
    float _mapDensity;
    int _cachedRulerMode;
    BOOL _cachedMapMode;
    OsmAnd::PointI _cachedTarget31;

    UIImage *_centerIconDay;
    UIImage *_centerIconNight;
    
    UITapGestureRecognizer* _singleGestureRecognizer;
    UITapGestureRecognizer* _doubleGestureRecognizer;
    UILongPressGestureRecognizer *_longSingleGestureRecognizer;
    UILongPressGestureRecognizer *_longDoubleGestureRecognizer;
    
    CLLocationCoordinate2D _tapPointOne;
    CLLocationCoordinate2D _tapPointTwo;
    
    NSDictionary<NSString *, NSNumber *> *_rulerLineAttrs;
    NSDictionary<NSString *, NSNumber *> *_rulerCircleAttrs;
    NSDictionary<NSString *, NSNumber *> *_rulerCircleAltAttrs;
    NSDictionary<NSString *, NSNumber *> *_rulerLineFontAttrs;
    
    CALayer *_fingerDistanceSublayer;
    OAFingerRulerDelegate *_fingerRulerDelegate;
    
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:@"OARulerWidget" owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OARulerWidget class]])
        {
            self = (OARulerWidget *)v;
            break;
        }
    }
    if (self)
    {
        self.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, DeviceScreenHeight);
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OARulerWidget class]])
        {
            self = (OARulerWidget *)v;
            break;
        }
    }
    if (self)
    {
        self.frame = frame;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _app = [OsmAndApp instance];
    _locationProvider = _app.locationServices;
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _singleGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(touchDetected:)];
    _singleGestureRecognizer.delegate = self;
    _singleGestureRecognizer.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:_singleGestureRecognizer];
    
    _doubleGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(touchDetected:)];
    _doubleGestureRecognizer.delegate = self;
    _doubleGestureRecognizer.numberOfTouchesRequired = 2;
    [self addGestureRecognizer:_doubleGestureRecognizer];
    
    _longSingleGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(touchDetected:)];
    _longSingleGestureRecognizer.numberOfTouchesRequired = 1;
    _longSingleGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longSingleGestureRecognizer];
    
    _longDoubleGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(touchDetected:)];
    _longDoubleGestureRecognizer.numberOfTouchesRequired = 2;
    _longDoubleGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longDoubleGestureRecognizer];
    self.multipleTouchEnabled = YES;
    _centerIconDay = [UIImage imageNamed:@"ic_ruler_center.png"];
    _centerIconNight = [UIImage imageNamed:@"ic_ruler_center_light.png"];
    _imageView.image = _settings.nightMode ? _centerIconNight : _centerIconDay;
    _cachedMapMode = _settings.nightMode;
    self.hidden = YES;
}

- (BOOL) updateInfo
{
    BOOL visible = [self rulerWidgetOn];
    if (visible)
    {
        if (!_fingerDistanceSublayer)
            [self initFingerLayer];
        
        if (_cachedMapMode != _settings.nightMode)
        {
            _imageView.image = _settings.nightMode ? _centerIconNight : _centerIconDay;
            _cachedMapMode = _settings.nightMode;
        }
        
        OAMapRendererView *mapRendererView = _mapViewController.mapView;
        visible = [_mapViewController calculateMapRuler] != 0
            && !_mapViewController.zoomingByGesture
            && !_mapViewController.rotatingByGesture;
        
        CGSize viewSize = self.bounds.size;
        float viewportScale = mapRendererView.viewportYScale;
        BOOL centerChanged  = _cachedViewportScale != viewportScale || _cachedWidth != viewSize.width || _cachedHeight != viewSize.height;
        if (centerChanged)
            [self changeCenter];
        
        BOOL modeChanged = _cachedRulerMode != _settings.rulerMode;
        if ((visible && _cachedRulerMode != RULER_MODE_NO_CIRCLES) || modeChanged)
        {
            _mapDensity = mapRendererView.currentPixelsToMetersScaleFactor;
            double fullMapScale = _mapDensity * kMapRulerMaxWidth * [[UIScreen mainScreen] scale];
            float mapAzimuth = mapRendererView.azimuth;
            float mapZoom = mapRendererView.zoom;
            const auto target31 = mapRendererView.target31;
            const auto target31Delta = _cachedTarget31 - target31;
            BOOL targetChanged = abs(target31Delta.y) > 1000000;
            if (targetChanged)
                _cachedTarget31 = target31;

            BOOL mapMoved = (targetChanged || centerChanged
                             || _cachedWidth != viewSize.width
                             || _cachedMapElevation != mapRendererView.elevationAngle
                             || _cachedMapAzimuth != mapAzimuth
                             || _cachedMapZoom != mapZoom
                             //|| _mapScaleUnrounded != fullMapScale
                             || modeChanged);
            _cachedWidth = viewSize.width;
            _cachedHeight = viewSize.height;
            _cachedMapElevation = mapRendererView.elevationAngle;
            _cachedMapAzimuth = mapAzimuth;
            _cachedMapZoom = mapZoom;
            _cachedViewportScale = viewportScale;
            _mapScaleUnrounded = fullMapScale;
            _mapScale = [_app calculateRoundedDist:_mapScaleUnrounded];
            _radius = (_mapScale / _mapDensity) / [[UIScreen mainScreen] scale];
            _maxRadius = [self calculateMaxRadiusInPx];
            if (mapMoved)
                [self setNeedsDisplay];
        }
        if (_twoFingersDist || _oneFingerDist)
            [_fingerDistanceSublayer setNeedsDisplay];

        _cachedRulerMode = _settings.rulerMode;
    }
    [self updateVisibility:visible];
    return YES;
}

- (void) updateAttributes
{
    _rulerLineAttrs = [_mapViewController getLineRenderingAttributes:@"rulerLine"];
    _rulerCircleAttrs = [_mapViewController getLineRenderingAttributes:@"rulerCircle"];
    _rulerCircleAltAttrs = [_mapViewController getLineRenderingAttributes:@"rulerCircleAlt"];
    _rulerLineFontAttrs = [_mapViewController getLineRenderingAttributes:@"rulerLineFont"];
}

- (float) calculateMaxRadiusInPx
{
    float centerY = self.center.y * _cachedViewportScale;
    float centerX = self.center.x;
    return MAX(centerY, centerX);
}

-(void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

- (void) initFingerLayer
{
    _fingerDistanceSublayer = [[CALayer alloc] init];
    _fingerDistanceSublayer.frame = self.bounds;
    _fingerDistanceSublayer.bounds = self.bounds;
    _fingerDistanceSublayer.contentsCenter = self.layer.contentsCenter;
    _fingerDistanceSublayer.contentsScale = [[UIScreen mainScreen] scale];
    _fingerRulerDelegate = [[OAFingerRulerDelegate alloc] initWithRulerWidget:self];
    _fingerDistanceSublayer.delegate = _fingerRulerDelegate;
}

- (void) layoutSubviews
{
    // resize your layers based on the view's new bounds
    _fingerDistanceSublayer.frame = self.bounds;
}

- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    UIGraphicsPushContext(ctx);
    [self updateAttributes];
    
    if (layer == self.layer)
    {
        if (_settings.rulerMode != RULER_MODE_NO_CIRCLES)
        {
            double maxRadiusCopy = _maxRadius;
            double scaleFactor = [_settings.mapDensity get:_settings.applicationMode];
            BOOL hasAttributes = _rulerCircleAttrs && _rulerCircleAltAttrs && [_rulerCircleAttrs count] != 0 && [_rulerCircleAltAttrs count] != 0;
            NSNumber *circleColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"color"] : [_rulerCircleAltAttrs valueForKey:@"color"]) :
            nil;
            UIColor *circleColor = circleColorAttr ? UIColorFromARGB(circleColorAttr.intValue) : [UIColor blackColor];
            NSNumber *textShadowColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"color_3"] : [_rulerCircleAltAttrs valueForKey:@"color_3"]) :
            nil;
            UIColor *textShadowColor =  textShadowColorAttr ? UIColorFromARGB(textShadowColorAttr.intValue) : [[UIColor whiteColor] colorWithAlphaComponent:0.5];
            NSNumber *shadowColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"shadowColor"] : [_rulerCircleAltAttrs valueForKey:@"shadowColor"]) :
            nil;
            CGColor *shadowColor = shadowColorAttr ? UIColorFromARGB(shadowColorAttr.intValue).CGColor : nil;
            float strokeWidth = (hasAttributes && [_rulerCircleAttrs valueForKey:@"strokeWidth"]) ? [_rulerCircleAttrs valueForKey:@"strokeWidth"].floatValue : 1.0;
            strokeWidth = scaleFactor < 1.0 ? 1.0 : strokeWidth / [[UIScreen mainScreen] scale] / scaleFactor;
            float shadowRadius = hasAttributes && [_rulerCircleAttrs valueForKey:@"shadowRadius"] ? [_rulerCircleAttrs valueForKey:@"shadowRadius"].floatValue / scaleFactor : 3.0;
            
            float strokeWidthText = ((hasAttributes && [_rulerCircleAttrs valueForKey:@"strokeWidth_3"]) ? [_rulerCircleAttrs valueForKey:@"strokeWidth_3"].floatValue / scaleFactor : 6.0) * 3.0;
            NSNumber *textColorAttr = hasAttributes ? (_cachedRulerMode == RULER_MODE_DARK ? [_rulerCircleAttrs valueForKey:@"color_2"] : [_rulerCircleAltAttrs valueForKey:@"color_2"]) :
            nil;
            UIColor *textColor =  textColorAttr ? UIColorFromARGB(textColorAttr.intValue) : [UIColor blackColor];
            UIFont *font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];

            CGContextSaveGState(ctx);

            CGPoint viewCenter = CGPointMake(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5);
            auto centerLatLon = OsmAnd::Utilities::convert31ToLatLon(_mapViewController.mapView.target31);
            double azimuth = _mapViewController.mapView.azimuth;
            double textAnchorAzimuthTop = azimuth;
            double textAnchorAzimuthBottom = OsmAnd::Utilities::normalizedAngleDegrees(azimuth + 180);
            double textAnchorAzimuthLeft = OsmAnd::Utilities::normalizedAngleDegrees(azimuth - 90);
            double textAnchorAzimuthRight = OsmAnd::Utilities::normalizedAngleDegrees(azimuth + 90);
            CGRect prevTitleRect1 = CGRectNull;
            CGRect prevTitleRect2 = CGRectNull;
            CGFloat titlePadding = TITLE_PADDING * [[UIScreen mainScreen] scale];
            for (int i = 1; maxRadiusCopy > _radius && _radius != 0; i++)
            {
                [circleColor set];
                CGContextSetLineWidth(ctx, strokeWidth);
                CGContextSetShadowWithColor(ctx, CGSizeZero, shadowRadius, shadowColor);

                maxRadiusCopy -= _radius;
                double r = _mapScale * i;
                NSMutableArray<NSArray<NSValue *> *> *arrays = [NSMutableArray array];
                NSMutableArray<NSValue *> *points = [NSMutableArray array];
                CGPoint textAnchorTop = CGPointZero;
                CGPoint textAnchorBottom = CGPointZero;
                CGPoint textAnchorLeft = CGPointZero;
                CGPoint textAnchorRight = CGPointZero;
                double anchorAzimuthDeltaTop = NAN;
                double anchorAzimuthDeltaBottom = NAN;
                double anchorAzimuthDeltaLeft = NAN;
                double anchorAzimuthDeltaRight = NAN;
                for (int a = -180; a <= 180; a += CIRCLE_ANGLE_STEP)
                {
                    auto latLon = OsmAnd::Utilities::rhumbDestinationPoint(centerLatLon, r, a);
                    if (ABS(latLon.latitude) > 90 || ABS(latLon.longitude) > 180)
                    {
                        if (points.count > 0)
                        {
                            [arrays addObject:points];
                            points = [NSMutableArray array];
                        }
                        continue;
                    }
                    
                    auto pos31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
                    CGPoint screenPoint;
                    [_mapViewController.mapView convert:&pos31 toScreen:&screenPoint checkOffScreen:YES];
                    [points addObject:[NSValue valueWithCGPoint:screenPoint]];
                    
                    BOOL outOfBounds = !CGRectContainsPoint(self.bounds, screenPoint);
                    double azumuthDeltaTop = ABS(textAnchorAzimuthTop - a);
                    if (isnan(anchorAzimuthDeltaTop) || azumuthDeltaTop < anchorAzimuthDeltaTop)
                    {
                        if (!outOfBounds && azumuthDeltaTop < 45)
                        {
                            textAnchorTop = screenPoint;
                            textAnchorTop.x = viewCenter.x;
                        }
                        anchorAzimuthDeltaTop = azumuthDeltaTop;
                    }
                    double azumuthDeltaBottom = ABS(textAnchorAzimuthBottom - a);
                    if (isnan(anchorAzimuthDeltaBottom) || azumuthDeltaBottom < anchorAzimuthDeltaBottom)
                    {
                        if (!outOfBounds && azumuthDeltaBottom < 45)
                        {
                            textAnchorBottom = screenPoint;
                            textAnchorBottom.x = viewCenter.x;
                        }
                        anchorAzimuthDeltaBottom = azumuthDeltaBottom;
                    }
                    double azumuthDeltaLeft = ABS(textAnchorAzimuthLeft - a);
                    if (isnan(anchorAzimuthDeltaLeft) || azumuthDeltaLeft < anchorAzimuthDeltaLeft)
                    {
                        if (!outOfBounds && azumuthDeltaLeft < 45)
                        {
                            textAnchorLeft = screenPoint;
                            textAnchorLeft.y = viewCenter.y * _cachedViewportScale;
                        }
                        anchorAzimuthDeltaLeft = azumuthDeltaLeft;
                    }
                    double azumuthDeltaRight = ABS(textAnchorAzimuthRight - a);
                    if (isnan(anchorAzimuthDeltaRight) || azumuthDeltaRight < anchorAzimuthDeltaRight)
                    {
                        if (!outOfBounds && azumuthDeltaRight < 45)
                        {
                            textAnchorRight = screenPoint;
                            textAnchorRight.y = viewCenter.y * _cachedViewportScale;
                        }
                        anchorAzimuthDeltaRight = azumuthDeltaRight;
                    }
                }
                CGPoint textAnchor1 = self.frame.size.height > self.frame.size.width ? textAnchorTop : textAnchorLeft;
                CGPoint textAnchor2 = self.frame.size.height > self.frame.size.width ? textAnchorBottom : textAnchorRight;

                if (points.count > 0)
                    [arrays addObject:points];
                
                for (NSArray<NSValue *> *points in arrays)
                {
                    CGPoint start = points[0].CGPointValue;
                    CGContextMoveToPoint(ctx, start.x, start.y);
                    for (NSInteger i = 1; i < points.count; i++)
                    {
                        CGPoint p = points[i].CGPointValue;
                        CGContextAddLineToPoint(ctx, p.x, p.y);
                    }
                    CGContextStrokePath(ctx);
                }
                
                NSString *dist = [_app getFormattedDistance:_mapScale * i];
                NSAttributedString *distString = [OAUtilities createAttributedString:dist font:font color:textColor strokeColor:nil strokeWidth:0];
                NSAttributedString *distShadowString = [OAUtilities createAttributedString:dist font:font color:textColor strokeColor:textShadowColor strokeWidth:strokeWidthText];

                CGSize titleSize = [distString size];
                if (!CGPointEqualToPoint(textAnchor1, CGPointZero))
                {
                    CGRect titleRect1 = CGRectMake(textAnchor1.x - titlePadding, textAnchor1.y - titlePadding, titleSize.width + titlePadding * 2.0, titleSize.height + titlePadding * 2.0);
                    if (CGRectIsNull(prevTitleRect1) || !CGRectIntersectsRect(prevTitleRect1, titleRect1))
                    {
                        [distShadowString drawAtPoint:CGPointMake(textAnchor1.x - titleSize.width / 2, textAnchor1.y - titleSize.height / 2)];
                        [distString drawAtPoint:CGPointMake(textAnchor1.x - titleSize.width / 2, textAnchor1.y - titleSize.height / 2)];
                        prevTitleRect1 = titleRect1;
                    }
                }
                if (!CGPointEqualToPoint(textAnchor2, CGPointZero))
                {
                    CGRect titleRect2 = CGRectMake(textAnchor2.x - titlePadding, textAnchor2.y - titlePadding, titleSize.width + titlePadding * 2.0, titleSize.height + titlePadding * 2.0);
                    BOOL intersectsWithFirstTitle = !CGRectIsNull(prevTitleRect1) && CGRectIntersectsRect(prevTitleRect1, titleRect2);
                    if ((CGRectIsNull(prevTitleRect2) || !CGRectIntersectsRect(prevTitleRect2, titleRect2)) && !intersectsWithFirstTitle)
                    {
                        [distShadowString drawAtPoint:CGPointMake(textAnchor2.x - titleSize.width / 2, textAnchor2.y - titleSize.height / 2)];
                        [distString drawAtPoint:CGPointMake(textAnchor2.x - titleSize.width / 2, textAnchor2.y - titleSize.height / 2)];
                        prevTitleRect2 = titleRect2;
                    }
                }
            }
            CGContextRestoreGState(ctx);
        }
    }
    UIGraphicsPopContext();
}

-(void) drawFingerRulerLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    UIGraphicsPushContext(ctx);
    if (layer == _fingerDistanceSublayer)
    {
        if (_oneFingerDist && !_twoFingersDist)
        {
            CLLocation *currLoc = [_app.locationServices lastKnownLocation];
            if (currLoc)
            {
                const auto dist = OsmAnd::Utilities::distance(_tapPointOne.longitude, _tapPointOne.latitude, currLoc.coordinate.longitude, currLoc.coordinate.latitude);
                NSArray<NSValue *> *linePoints = [_mapViewController.mapView getVisibleLineFromLat:currLoc.coordinate.latitude fromLon:currLoc.coordinate.longitude toLat:_tapPointOne.latitude toLon:_tapPointOne.longitude];
                if (linePoints.count == 2)
                {
                    CGPoint a = linePoints[0].CGPointValue;
                    CGPoint b = linePoints[1].CGPointValue;
                    double angle = [OAMapUtils getAngleBetween:a end:b];
                    NSString *distance = [_app getFormattedDistance:dist];
                    _rulerDistance = distance;
                    [self drawLineBetweenPoints:a end:b context:ctx distance:distance];
                    [self drawDistance:ctx distance:distance angle:angle start:a end:b];
                    if ([_mapViewController isLocationVisible:_tapPointOne.latitude longitude:_tapPointOne.longitude])
                    {
                        UIImage *iconToUse = _settings.nightMode ? _centerIconNight : _centerIconDay;
                        CGRect pointRect = CGRectMake(b.x - iconToUse.size.width / 2, b.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
                        [iconToUse drawInRect:pointRect];
                    }
                }
            }
        }
        if (_twoFingersDist && !_oneFingerDist)
        {
            NSArray<NSValue *> *linePoints = [_mapViewController.mapView getVisibleLineFromLat:_tapPointOne.latitude fromLon:_tapPointOne.longitude toLat:_tapPointTwo.latitude toLon:_tapPointTwo.longitude];
            if (linePoints.count == 2)
            {
                CGPoint a = linePoints[0].CGPointValue;
                CGPoint b = linePoints[1].CGPointValue;
                double angle = [OAMapUtils getAngleBetween:a end:b];
                const auto dist = OsmAnd::Utilities::distance(_tapPointOne.longitude, _tapPointOne.latitude, _tapPointTwo.longitude, _tapPointTwo.latitude);
                NSString *distance = [_app getFormattedDistance:dist];
                _rulerDistance = distance;
                [self drawLineBetweenPoints:a end:b context:ctx distance:distance];
                [self drawDistance:ctx distance:distance angle:angle start:a end:b];
                UIImage *iconToUse = _settings.nightMode ? _centerIconNight : _centerIconDay;
                if ([_mapViewController isLocationVisible:_tapPointOne.latitude longitude:_tapPointOne.longitude])
                {
                    CGRect pointOneRect = CGRectMake(a.x - iconToUse.size.width / 2, a.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
                    [iconToUse drawInRect:pointOneRect];
                }
                if ([_mapViewController isLocationVisible:_tapPointTwo.latitude longitude:_tapPointTwo.longitude])
                {
                    CGRect pointTwoRect = CGRectMake(b.x - iconToUse.size.width / 2, b.y - iconToUse.size.height / 2, iconToUse.size.width, iconToUse.size.height);
                    [iconToUse drawInRect:pointTwoRect];
                }
            }
        }
        OAMapWidgetRegInfo *rulerWidget = [[OARootViewController instance].mapPanel.mapWidgetRegistry widgetByKey:@"radius_ruler"];
        if (rulerWidget)
            [rulerWidget.widget updateInfo];
    }
    UIGraphicsPopContext();
}

- (void) drawDistance:(CGContextRef)ctx distance:(NSString *)distance angle:(double)angle start:(CGPoint)start end:(CGPoint)end
{
    CGPoint middlePoint = CGPointMake((start.x + end.x) / 2, (start.y + end.y) / 2);
    UIFont *font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    
    BOOL useDefaults = !_rulerLineFontAttrs || [_rulerLineFontAttrs count] == 0;
    NSNumber *strokeColorAttr = useDefaults ? nil : [_rulerLineFontAttrs objectForKey:@"color_2"];
    UIColor *strokeColor = strokeColorAttr ? UIColorFromARGB(strokeColorAttr.intValue) : [UIColor whiteColor];
    NSNumber *colorAttr = useDefaults ? nil : [_rulerLineFontAttrs objectForKey:@"color"];
    UIColor *color = colorAttr ? UIColorFromARGB(colorAttr.intValue) : [UIColor blackColor];
    NSNumber *strokeWidthAttr = useDefaults ? nil : [_rulerLineFontAttrs valueForKey:@"strokeWidth_2"];
    float strokeWidth = (strokeWidthAttr ? strokeWidthAttr.floatValue / [[UIScreen mainScreen] scale] : 4.0) * 4.0;
    
    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    attributes[NSParagraphStyleAttributeName] = paragraphStyle;

    NSAttributedString *string = [OAUtilities createAttributedString:distance font:font color:color strokeColor:nil strokeWidth:0];
    NSAttributedString *shadowString = [OAUtilities createAttributedString:distance font:font color:color strokeColor:strokeColor strokeWidth:strokeWidth];

    CGSize titleSize = [string size];
    CGRect rect = CGRectMake(middlePoint.x - (titleSize.width / 2), middlePoint.y - (titleSize.height / 2), titleSize.width, titleSize.height);
    
    CGFloat xMid = CGRectGetMidX(rect);
    CGFloat yMid = CGRectGetMidY(rect);
    CGContextSaveGState(ctx);
    {
        CGContextTranslateCTM(ctx, xMid, yMid);
        CGContextRotateCTM(ctx, angle);
        
        CGRect newRect = rect;
        newRect.origin.x = -newRect.size.width / 2;
        newRect.origin.y = -newRect.size.height / 2 + LABEL_OFFSET;
        
        [shadowString drawWithRect:newRect options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        [string drawWithRect:newRect options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        CGContextStrokePath(ctx);
    }
    CGContextRestoreGState(ctx);
}

- (void) drawLineBetweenPoints:(CGPoint) start end:(CGPoint) end context:(CGContextRef) ctx distance:(NSString *) distance
{
    CGContextSaveGState(ctx);
    {
        NSNumber *colorAttr = _rulerLineAttrs ? [_rulerLineAttrs objectForKey:@"color"] : nil;
        UIColor *color = colorAttr ? UIColorFromARGB(colorAttr.intValue) : [UIColor blackColor];
        [color set];
        CGContextSetLineWidth(ctx, 4.0);
        CGFloat dashLengths[] = {10, 5};
        CGContextSetLineDash(ctx, 0.0, dashLengths , 2);
        CGContextMoveToPoint(ctx, start.x, start.y);
        CGContextAddLineToPoint(ctx, end.x, end.y);
        CGContextStrokePath(ctx);
    }
    CGContextRestoreGState(ctx);
}

- (void) touchDetected:(UITapGestureRecognizer *)recognizer
{
    // Handle gesture only when it is ended
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    if ([recognizer numberOfTouches] == 1 && !_twoFingersDist) {
        _oneFingerDist = YES;
        _twoFingersDist = NO;
        _tapPointOne = [self getTouchPointCoord:[recognizer locationInView:self]];
        if (_fingerDistanceSublayer.superlayer != self.layer)
            [self.layer insertSublayer:_fingerDistanceSublayer above:self.layer];
        [_fingerDistanceSublayer setNeedsDisplay];
    }
    
    if ([recognizer numberOfTouches] == 2 && !_oneFingerDist) {
        _twoFingersDist = YES;
        _oneFingerDist = NO;
        CGPoint first = [recognizer locationOfTouch:0 inView:self];
        CGPoint second = [recognizer locationOfTouch:1 inView:self];
        _tapPointOne = [self getTouchPointCoord:first];
        _tapPointTwo = [self getTouchPointCoord:second];
        if (_fingerDistanceSublayer.superlayer != self.layer)
            [self.layer insertSublayer:_fingerDistanceSublayer above:self.layer];
        [_fingerDistanceSublayer setNeedsDisplay];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector:@selector(hideTouchRuler) object: self];
    [self performSelector:@selector(hideTouchRuler) withObject: self afterDelay: DRAW_TIME];
}

- (void) changeCenter
{
    _imageView.center = CGPointMake(self.frame.size.width * 0.5,
                                    self.frame.size.height * 0.5 * _mapViewController.mapView.viewportYScale);
}

- (void) hideTouchRuler
{
    _rulerDistance = nil;
    _oneFingerDist = NO;
    _twoFingersDist = NO;
    if (_fingerDistanceSublayer.superlayer == self.layer)
        [_fingerDistanceSublayer removeFromSuperlayer];
}

- (void) onMapSourceUpdated
{
    if ([self rulerWidgetOn])
        [self setNeedsDisplay];
}

- (BOOL) rulerWidgetOn
{
    return [[OARootViewController instance].mapPanel.mapWidgetRegistry isVisible:@"radius_ruler"];
}

- (BOOL) updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        self.hidden = !visible;
        if (_delegate)
            [_delegate widgetVisibilityChanged:nil visible:visible];
        
        return YES;
    }
    return NO;
}

- (CLLocationCoordinate2D) getTouchPointCoord:(CGPoint)touchPoint
{
    touchPoint.x *= _mapViewController.mapView.contentScaleFactor;
    touchPoint.y *= _mapViewController.mapView.contentScaleFactor;
    OsmAnd::PointI touchLocation;
    [_mapViewController.mapView convert:touchPoint toLocation:&touchLocation];
    
    double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
    double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
    return CLLocationCoordinate2DMake(lat, lon);
}

@end
