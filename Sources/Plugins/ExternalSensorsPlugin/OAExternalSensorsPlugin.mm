//
//  OASensorsPlugin.mm
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 03.11.2023.
//  Copyright (c) 2023 OsmAnd. All rights reserved.
//

#import "OAExternalSensorsPlugin.h"
#import "OARootViewController.h"
#import "OAMapInfoController.h"
#import "OAMapHudViewController.h"
#import "OAWeatherWidget.h"
#import "OAMapInfoWidgetsFactory.h"
#import "OAMapWidgetRegInfo.h"
#import "OAIAPHelper.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

#define PLUGIN_ID kInAppId_Addon_External_Sensors

#define kLastUsedExternalSensorKey @"kLastUsedExternalSensorKey"

NSString * const OATrackRecordingNone = @"OATrackRecordingNone";
NSString * const OATrackRecordingAnyConnected = @"OATrackRecordingAnyConnected";

@implementation OAExternalSensorsPlugin
{
    OACommonBoolean *_lastUsedSensor;
    OACommonString *_speedSensorWriteToTrackDeviceID;
    OACommonString *_cadenceSensorWriteToTrackDeviceID;
    OACommonString *_powerSensorWriteToTrackDeviceID;
    OACommonString *_heartSensorWriteToTrackDeviceID;
    OACommonString *_temperatureSensorWriteToTrackDeviceID;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _lastUsedSensor = [OACommonBoolean withKey:kLastUsedExternalSensorKey defValue:NO];
        
        _speedSensorWriteToTrackDeviceID = [OACommonString withKey:@"speed_sensor_write_to_track_device" defValue:OATrackRecordingNone];
        _cadenceSensorWriteToTrackDeviceID = [OACommonString withKey:@"cadence_sensor_write_to_track_device" defValue:OATrackRecordingNone];
        _powerSensorWriteToTrackDeviceID = [OACommonString withKey:@"power_sensor_write_to_track_device" defValue:OATrackRecordingNone];
        _heartSensorWriteToTrackDeviceID = [OACommonString withKey:@"heart_rate_sensor_write_to_track_device" defValue:OATrackRecordingNone];
        _temperatureSensorWriteToTrackDeviceID = [OACommonString withKey:@"temperature_sensor_write_to_track_device" defValue:OATrackRecordingNone];
        
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.heartRate appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.bicycleCadence appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.bicyclePower appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.bicycleDistance appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.bicycleSpeed appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.temperature appModes:@[]];
    }
    return self;
}

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (void)disable
{
    [super disable];
    [[OADeviceHelper shared] disconnectAllDevices];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [[OARootViewController instance] updateLeftPanelMenu];
}

- (BOOL)isEnabled
{
    return [super isEnabled] && [OAIAPHelper isSensorPurchased];
}

- (BOOL)hasCustomSettings
{
    return YES;
}

- (NSArray<NSString *> *)getWidgetIds
{
    return @[OAWidgetType.heartRate.id,
             OAWidgetType.bicycleCadence.id,
             OAWidgetType.bicyclePower.id,
             OAWidgetType.bicycleDistance.id,
             OAWidgetType.bicycleSpeed.id,
             OAWidgetType.temperature.id];
}

- (NSArray<OAWidgetType *> *)getExternalSensorTrackDataType
{
    return @[OAWidgetType.heartRate,
             OAWidgetType.bicycleCadence,
             OAWidgetType.bicyclePower,
             OAWidgetType.bicycleSpeed,
             OAWidgetType.temperature];
}

- (void)createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode
{
    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];
    auto widgetTypeArray = @[OAWidgetType.heartRate,
                             OAWidgetType.bicycleCadence,
                             OAWidgetType.bicyclePower,
                             OAWidgetType.bicycleDistance,
                             OAWidgetType.bicycleSpeed,
                             OAWidgetType.temperature];
    for (OAWidgetType *widgetType in widgetTypeArray)
    {
        [delegate addWidget:[creator createWidgetInfoWithWidget:(SensorTextWidget *) [self createMapWidgetForParams:widgetType appMode:appMode]]];
    }
}

- (OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType appMode:(OAApplicationMode *)appMode
{
    return [[SensorTextWidget alloc] initWithCustomId:@"" widgetType:widgetType appMode:appMode widgetParams:nil];
}

- (NSString *) getName
{
    return OALocalizedString(@"external_sensors_plugin_name");
}

- (NSString *) getDescription
{
    return OALocalizedString(@"external_sensors_plugin_description");
}

- (void)attachAdditionalInfoToRecordedTrack:(CLLocation *)location json:(NSMutableData *)json
{
    for (OAWidgetType *widgetType in [self getExternalSensorTrackDataType])
    {
        [self attachDeviceSensorInfoToRecordedTrack:widgetType json:json];
    }
}

- (void)attachDeviceSensorInfoToRecordedTrack:(OAWidgetType *)widgetType json:(NSMutableData *)json
{
    OAApplicationMode *selectedAppMode = [[OAAppSettings sharedManager].applicationMode get];
    OACommonString *deviceIdPref = [self getWriteToTrackDeviceIdPref:widgetType];
    if (deviceIdPref)
    {
        NSString *deviceId = [deviceIdPref get:selectedAppMode];
        if (deviceId && ![deviceId isEqualToString:OATrackRecordingNone])
        {
            OADevice *device = nil;
            if ([deviceId isEqualToString:OATrackRecordingAnyConnected])
                device = [[OADeviceHelper shared] getConnectedDevicesForWidgetWithType:widgetType].firstObject;
            else
                device = [[OADeviceHelper shared] getConnectedOrPaireDisconnectedDeviceForType:widgetType deviceId:deviceId];
            
            if (device)
                [device writeSensorDataToJsonWithJson:json widgetDataFieldType:widgetType];
        }
    }
}

- (NSString *)getDeviceIdForWidgetType:(OAWidgetType *)widgetType appMode:(OAApplicationMode *)appMode {
    if ([widgetType isEqual:OAWidgetType.bicycleSpeed])
        return [_speedSensorWriteToTrackDeviceID get:appMode];
    if ([widgetType isEqual:OAWidgetType.bicyclePower])
        return [_powerSensorWriteToTrackDeviceID get:appMode];
    if ([widgetType isEqual:OAWidgetType.bicycleCadence])
        return [_cadenceSensorWriteToTrackDeviceID get:appMode];
    if ([widgetType isEqual:OAWidgetType.heartRate])
        return [_heartSensorWriteToTrackDeviceID get:appMode];
    if ([widgetType isEqual:OAWidgetType.temperature])
        return [_temperatureSensorWriteToTrackDeviceID get:appMode];
    return @"";
}

- (void)saveDeviceId:(NSString *)deviceID widgetType:(OAWidgetType *)widgetType appMode:(OAApplicationMode *)appMode {
    if ([widgetType isEqual:OAWidgetType.bicycleSpeed])
        [_speedSensorWriteToTrackDeviceID set:deviceID mode:appMode];
    if ([widgetType isEqual:OAWidgetType.bicyclePower])
        [_powerSensorWriteToTrackDeviceID set:deviceID mode:appMode];
    if ([widgetType isEqual:OAWidgetType.bicycleCadence])
        [_cadenceSensorWriteToTrackDeviceID set:deviceID mode:appMode];
    if ([widgetType isEqual:OAWidgetType.heartRate])
        [_heartSensorWriteToTrackDeviceID set:deviceID mode:appMode];
    if ([widgetType isEqual:OAWidgetType.temperature])
        [_temperatureSensorWriteToTrackDeviceID set:deviceID mode:appMode];
}

- (OACommonString *)getWriteToTrackDeviceIdPref:(OAWidgetType *)dataType
{
    if ([dataType isEqual:OAWidgetType.bicycleSpeed])
        return _speedSensorWriteToTrackDeviceID;
    if ([dataType isEqual:OAWidgetType.bicyclePower])
        return _powerSensorWriteToTrackDeviceID;
    if ([dataType isEqual:OAWidgetType.bicycleCadence])
        return _cadenceSensorWriteToTrackDeviceID;
    if ([dataType isEqual:OAWidgetType.heartRate])
        return _heartSensorWriteToTrackDeviceID;
    if ([dataType isEqual:OAWidgetType.temperature])
        return _temperatureSensorWriteToTrackDeviceID;
    return nil;
}

@end
