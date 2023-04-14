//
//  OACustomPickerTableViewCell.m
//  OsmAnd Maps
//
//  Created by igor on 27.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACustomPickerTableViewCell.h"

@implementation OACustomPickerTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.picker.dataSource = self;
    self.picker.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setDataArray:(NSArray<NSString *> *)dataArray
{
    _dataArray = dataArray;
    [self.picker reloadAllComponents];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.dataArray.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return self.dataArray[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (self.delegate)
        [self.delegate customPickerValueChanged:self.dataArray[row] tag:pickerView.tag];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *pickerLabel = (UILabel *) view;
    if (!pickerLabel)
    {
        pickerLabel = [[UILabel alloc] init];
        pickerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        pickerLabel.textAlignment = NSTextAlignmentCenter;
        pickerLabel.adjustsFontForContentSizeCategory = YES;
    }
    pickerLabel.text = _dataArray[row];
    return pickerLabel;
}

@end
