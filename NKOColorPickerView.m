/*
 The MIT License (MIT)
 
 Copyright (C) 2014 Carlos Vidal
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software without restriction, including without
 limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial
 portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
 EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
 OR OTHER DEALINGS IN THE SOFTWARE LICENSE
 */

//
//  NKOColorPickerView.h
//  ColorPicker
//
//  Created by Carlos Vidal
//  Based on work by Fabián Cañas and Gilly Dekel
//

#import "NKOColorPickerView.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

//NKOBrightnessView
@interface NKOBrightnessView: UIView

@property (nonatomic, strong) UIColor *color;

@end

//UIImage category
@interface UIImage(NKO)

- (UIImage*)nko_tintImageWithColor:(UIColor*)tintColor;

@end

//NKOColorPickerView
#define buttonTintColor [UIColor colorWithRed:236/255.0 green:240/255.0 blue:241/255.0 alpha:1.0]
#define buttonBackgroundColor [UIColor colorWithWhite:20/255.0 alpha:1.0]
#define buttonBorderColor [UIColor colorWithWhite:10/255.0 alpha:1.0]
#define viewBackgroundColor [UIColor colorWithWhite:30/255.0 alpha:1.0]

CGFloat const NKOPickerViewSelectedColorWidthAndHeight  = 40.f;
CGFloat const NKOPickerViewGradientViewHeight           = 14.f;
CGFloat const NKOPickerViewGradientTopMargin            = 20.f;
CGFloat const NKOPickerViewDefaultMargin                = 10.f;
CGFloat const NKOPickerViewBrightnessIndicatorWidthAndHeight    = 20.0;
CGFloat const NKOPickerViewCrossHairsWidthAndHeight     = 38.f;
CGFloat const NKOPickerViewButtonsWidthAndHeight        = 40.f;

@interface NKOColorPickerView()

@property (nonatomic, strong) NKOBrightnessView *gradientView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UIView *selectedColorView;
@property (nonatomic, strong) UIImageView *brightnessIndicator;
@property (nonatomic, strong) UIImageView *hueSatImage;
@property (nonatomic, strong) UIView *crossHairs;

@property (nonatomic, assign) CGFloat currentBrightness;
@property (nonatomic, assign) CGFloat currentSaturation;
@property (nonatomic, assign) CGFloat currentHue;

@end

@implementation NKOColorPickerView

- (id)initWithFrame:(CGRect)frame
              color:(UIColor*)color
didChangeColorBlock:(NKOColorPickerDidChangeColorBlock)didChangeColorBlock
     didCancelBlock:(NKOColorPickerDidCancelBlock)didCancelBlock {
    
    self = [super init];
    
    if (self != nil){
        self.frame = frame;
        self.backgroundColor = viewBackgroundColor;
        self.layer.cornerRadius = 6;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor colorWithWhite:50/255.9 alpha:1.0].CGColor;
        self->_color = color;
        self->_didChangeColorBlock = didChangeColorBlock;
        self->_didCancelBlock = didCancelBlock;
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    
    [super willMoveToSuperview:newSuperview];
    
    [self.crossHairs setHidden:NO];
    [self.brightnessIndicator setHidden:NO];
    [self.selectedColorView setHidden:NO];
    
    if (self->_color == nil){
        self.color = [self _defaultTintColor];
    } else {
        self.color = _color;
    }
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    self.selectedColorView.frame = CGRectMake(CGRectGetWidth(self.frame)/2 - NKOPickerViewSelectedColorWidthAndHeight/2,
                                              NKOPickerViewDefaultMargin,
                                              NKOPickerViewSelectedColorWidthAndHeight,
                                              NKOPickerViewSelectedColorWidthAndHeight);
    
    self.cancelButton.frame = CGRectMake(NKOPickerViewDefaultMargin,
                                         NKOPickerViewDefaultMargin,
                                         NKOPickerViewButtonsWidthAndHeight,
                                         NKOPickerViewButtonsWidthAndHeight);
    
    self.doneButton.frame = CGRectMake(CGRectGetWidth(self.frame) - NKOPickerViewDefaultMargin - NKOPickerViewButtonsWidthAndHeight,
                                       NKOPickerViewDefaultMargin,
                                       NKOPickerViewButtonsWidthAndHeight,
                                       NKOPickerViewButtonsWidthAndHeight);
    
    self.gradientView.frame = CGRectMake(2*NKOPickerViewDefaultMargin,
                                         CGRectGetHeight(self.frame) - NKOPickerViewGradientViewHeight - NKOPickerViewDefaultMargin,
                                         CGRectGetWidth(self.frame) - (NKOPickerViewDefaultMargin*4),
                                         NKOPickerViewGradientViewHeight);
    
    self.hueSatImage.frame = CGRectMake(2*NKOPickerViewDefaultMargin,
                                        NKOPickerViewDefaultMargin + NKOPickerViewSelectedColorWidthAndHeight + 2*NKOPickerViewDefaultMargin,
                                        [self availableWidthAndHeightForHueSat],
                                        [self availableWidthAndHeightForHueSat]);
    
    [self _updateBrightnessPosition];
    [self _updateCrosshairPosition];
}

- (CGFloat)availableWidthAndHeightForHueSat {
    
    CGFloat availableWidth = CGRectGetWidth(self.frame) - NKOPickerViewDefaultMargin*4;
    CGFloat availableHeight = CGRectGetHeight(self.frame) - 2*NKOPickerViewDefaultMargin - 4*NKOPickerViewDefaultMargin - NKOPickerViewSelectedColorWidthAndHeight - NKOPickerViewGradientViewHeight;
    return MIN(availableWidth, availableHeight);
}

#pragma mark - Public methods

- (void)setColor:(UIColor *)newColor {
    
    CGFloat hue = 0.f;
    CGFloat saturation = 0.f;
    [newColor getHue:&hue saturation:&saturation brightness:nil alpha:nil];
    
    self.currentHue = hue;
    self.currentSaturation = saturation;
    [self _setColor:newColor];
    [self _updateSelectedColor];
    [self _updateGradientColor];
    [self _updateBrightnessPosition];
    [self _updateCrosshairPosition];
}

#pragma mark - Private methods

- (void)_setColor:(UIColor *)newColor {
    
    if (![self->_color isEqual:newColor]){
        CGFloat brightness;
        [newColor getHue:NULL saturation:NULL brightness:&brightness alpha:NULL];
        CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(newColor.CGColor));
        
        if (colorSpaceModel==kCGColorSpaceModelMonochrome) {
            const CGFloat *c = CGColorGetComponents(newColor.CGColor);
            self->_color = [UIColor colorWithHue:0 saturation:0 brightness:c[0] alpha:1.0];
        }
        else{
            self->_color = [newColor copy];
        }
        
        _selectedColorView.backgroundColor = newColor;
    }
}

- (void)tappedCancelButton {
    
    if (self.didCancelBlock != nil){
        self.didCancelBlock();
    }
}

- (void)tappedDoneButton {
    
    if (self.didChangeColorBlock != nil){
        self.didChangeColorBlock(self.color);
    }
}

- (void)_updateBrightnessPosition {
    
    CGFloat brightness = 0.f;
    [self.color getHue:nil saturation:nil brightness:&brightness alpha:nil];
    
    self.currentBrightness = brightness;
    
    CGPoint brightnessPosition;
    brightnessPosition.x = (1.0-self.currentBrightness)*self.gradientView.frame.size.width + self.gradientView.frame.origin.x;
    brightnessPosition.y = self.gradientView.center.y;
    
    self.brightnessIndicator.center = brightnessPosition;
}

- (void)_updateCrosshairPosition {
    
    CGPoint hueSatPosition;
    
    CGFloat radius = self.currentSaturation * self.hueSatImage.bounds.size.width/2;
    CGFloat theta = self.currentHue * 2*M_PI;
    hueSatPosition.x = self.hueSatImage.center.x + radius*cosf(theta);
    hueSatPosition.y = self.hueSatImage.center.y - radius*sinf(theta);
    
    self.crossHairs.center = hueSatPosition;
    [self _updateGradientColor];
    [self _updateSelectedColor];
}

- (void)_updateSelectedColor {
    self.selectedColorView.backgroundColor = [UIColor colorWithHue:self.currentHue saturation:self.currentSaturation brightness:self.currentBrightness alpha:1.0];
}

- (void)_updateGradientColor {
    
    UIColor *gradientColor = [UIColor colorWithHue:self.currentHue
                                        saturation:self.currentSaturation
                                        brightness:1.0
                                             alpha:1.0];
    
    self.crossHairs.layer.backgroundColor = gradientColor.CGColor;
    
    [self.gradientView setColor:gradientColor];
}

- (void)_updateHueSatWithMovement:(CGPoint)position {
    
    CGFloat x = position.x - self.hueSatImage.center.x;
    CGFloat y = self.hueSatImage.center.y - position.y;
    
    CGFloat radians = atan2f(y, x);
    if (radians < 0) {
        radians = 2*M_PI + radians;
    }
    
    self.currentHue = radians/(2*M_PI);
    
    self.currentSaturation = hypotf(x, y)/(self.hueSatImage.bounds.size.width*0.5);
    
    NSLog(@"\n\n x: %f\ny: %f\nhue: %f\nsat: %f", x,y,self.currentHue,self.currentSaturation);
    
    UIColor *_tcolor = [UIColor colorWithHue:self.currentHue
                                  saturation:self.currentSaturation
                                  brightness:self.currentBrightness
                                       alpha:1.0];
    UIColor *gradientColor = [UIColor colorWithHue:self.currentHue
                                        saturation:self.currentSaturation
                                        brightness:1.0
                                             alpha:1.0];
    
    
    self.crossHairs.layer.backgroundColor = gradientColor.CGColor;
    [self _updateGradientColor];
    [self _updateSelectedColor];
    [self _setColor:_tcolor];
}

- (void)_updateBrightnessWithMovement:(CGPoint)position {
    
    self.currentBrightness = 1.0 - ((position.x - self.gradientView.frame.origin.x)/self.gradientView.frame.size.width) ;
    
    UIColor *_tcolor = [UIColor colorWithHue:self.currentHue
                                  saturation:self.currentSaturation
                                  brightness:self.currentBrightness
                                       alpha:1.0];
    [self _setColor:_tcolor];
}

- (UIColor*)_defaultTintColor {
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    if ([window respondsToSelector:@selector(tintColor)]) {
        return [window tintColor];
    }
    return [UIColor whiteColor];
}

- (UIImage*)_imageWithName:(NSString*)name {
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        NSBundle *libraryBundle = [NSBundle bundleForClass:[self class]];
        UIImage *image = [UIImage imageNamed:name inBundle:libraryBundle compatibleWithTraitCollection:nil];
        
        return image;
    }
    else {
        UIImage *image = [UIImage imageNamed:name];
        
        return image;
    }
}

#pragma mark - Touch Handling methods

-(float)distanceFromPosition:(CGPoint)position toCenter:(CGPoint)center
{
    CGFloat dx=position.x-center.x;
    CGFloat dy=position.y-center.y;
    
    return sqrt(dx*dx + dy*dy);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches){
        [self dispatchTouchEvent:[touch locationInView:self]];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches){
        [self dispatchTouchEvent:[touch locationInView:self]];
    }
}

- (void)dispatchTouchEvent:(CGPoint)position {
    if ([self distanceFromPosition:position toCenter:self.hueSatImage.center] <= self.hueSatImage.bounds.size.width/2){
        self.crossHairs.center = position;
        [self _updateHueSatWithMovement:position];
    }
    else if (CGRectContainsPoint(self.gradientView.frame, position)) {
        self.brightnessIndicator.center = CGPointMake(position.x, self.gradientView.center.y);
        [self _updateBrightnessWithMovement:position];
    }
}

#pragma mark - Lazy loading

- (UIButton*)cancelButton {
    
    if (_cancelButton == nil) {
        _cancelButton = [[UIButton alloc] init];
        
        [_cancelButton addTarget:self action:@selector(tappedCancelButton) forControlEvents:UIControlEventTouchUpInside];
        
        _cancelButton.frame = CGRectMake(NKOPickerViewDefaultMargin,
                                         NKOPickerViewDefaultMargin,
                                         NKOPickerViewButtonsWidthAndHeight,
                                         NKOPickerViewButtonsWidthAndHeight);
        
        UIImage *cancelImage = [[UIImage imageNamed:@"xmark_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [_cancelButton setImage:cancelImage forState:UIControlStateNormal];
        
        _cancelButton.tintColor = buttonTintColor;
        
        _cancelButton.layer.masksToBounds = YES;
        _cancelButton.layer.cornerRadius = NKOPickerViewButtonsWidthAndHeight/2;
        _cancelButton.layer.borderWidth = 1.f;
        _cancelButton.layer.borderColor = buttonBorderColor.CGColor;
        _cancelButton.backgroundColor = buttonBackgroundColor;
    }
    
    if (_cancelButton.superview == nil){
        [self addSubview:_cancelButton];
    }
    
    
    return _cancelButton;
}

- (UIButton*)doneButton {
    
    if (_doneButton == nil) {
        _doneButton = [[UIButton alloc] init];
        
        [_doneButton addTarget:self action:@selector(tappedDoneButton) forControlEvents:UIControlEventTouchUpInside];
        
        _doneButton.frame = CGRectMake(CGRectGetWidth(self.frame) - NKOPickerViewDefaultMargin - NKOPickerViewButtonsWidthAndHeight,
                                       NKOPickerViewDefaultMargin,
                                       NKOPickerViewButtonsWidthAndHeight,
                                       NKOPickerViewButtonsWidthAndHeight);
        
        UIImage *doneImage = [[UIImage imageNamed:@"tickmark_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        [_doneButton setImage:doneImage forState:UIControlStateNormal];
        _doneButton.tintColor = buttonTintColor;
        
        _doneButton.layer.masksToBounds = YES;
        _doneButton.layer.cornerRadius = NKOPickerViewButtonsWidthAndHeight/2;
        _doneButton.layer.borderWidth = 1.f;
        _doneButton.layer.borderColor = buttonBorderColor.CGColor;
        _doneButton.backgroundColor = buttonBackgroundColor;
        
    }
    
    if (_doneButton.superview == nil){
        [self addSubview:_doneButton];
    }
    
    
    return _doneButton;
}

- (UIView*)selectedColorView {
    
    if (_selectedColorView == nil) {
        _selectedColorView = [[UIView alloc] init];
        _selectedColorView.frame = CGRectMake(CGRectGetWidth(self.frame)/2 - NKOPickerViewSelectedColorWidthAndHeight/2,
                                              NKOPickerViewDefaultMargin,
                                              NKOPickerViewSelectedColorWidthAndHeight,
                                              NKOPickerViewSelectedColorWidthAndHeight);
        
        _selectedColorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        _selectedColorView.layer.masksToBounds = YES;
        _selectedColorView.layer.cornerRadius = NKOPickerViewSelectedColorWidthAndHeight/2;
    }
    
    if (_selectedColorView.superview == nil){
        [self addSubview:_selectedColorView];
    }
    
    return _selectedColorView;
}

- (NKOBrightnessView*)gradientView {
    
    if (self->_gradientView == nil){
        self->_gradientView = [[NKOBrightnessView alloc] init];
        self->_gradientView.frame = CGRectMake(2*NKOPickerViewDefaultMargin,
                                               CGRectGetHeight(self.frame) - NKOPickerViewGradientViewHeight - NKOPickerViewDefaultMargin,
                                               CGRectGetWidth(self.frame)-(NKOPickerViewDefaultMargin*4),
                                               NKOPickerViewGradientViewHeight);
        
        self->_gradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        
        self->_gradientView.layer.masksToBounds = YES;
        self->_gradientView.layer.cornerRadius = NKOPickerViewGradientViewHeight/2;
        self->_gradientView.layer.shadowColor = [UIColor blackColor].CGColor;
        self->_gradientView.layer.shadowOffset = CGSizeMake(0, 1);
        self->_gradientView.layer.shadowRadius = 1;
        self->_gradientView.layer.shadowOpacity = 0.5f;
        
    }
    
    if (self->_gradientView.superview == nil){
        [self addSubview:self->_gradientView];
    }
    
    return self->_gradientView;
}

- (UIImageView*)hueSatImage {
    
    if (self->_hueSatImage == nil){
        self->_hueSatImage = [[UIImageView alloc] initWithImage:[self _imageWithName:@"nko_colormap.png"]];
        self->_hueSatImage.frame = CGRectMake(2*NKOPickerViewDefaultMargin,
                                              NKOPickerViewDefaultMargin + NKOPickerViewSelectedColorWidthAndHeight + 2*NKOPickerViewDefaultMargin,
                                              [self availableWidthAndHeightForHueSat],
                                              [self availableWidthAndHeightForHueSat]);
        
        self->_hueSatImage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self->_hueSatImage.layer.masksToBounds = YES;
        self->_hueSatImage.layer.cornerRadius = _hueSatImage.bounds.size.width/2;
    }
    
    if (self->_hueSatImage.superview == nil){
        [self addSubview:self->_hueSatImage];
    }
    
    return self->_hueSatImage;
}

- (UIView*)crossHairs {
    
    if (self->_crossHairs == nil){
        self->_crossHairs = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.frame)*0.5,
                                                                     CGRectGetHeight(self.frame)*0.5,
                                                                     NKOPickerViewCrossHairsWidthAndHeight,
                                                                     NKOPickerViewCrossHairsWidthAndHeight)];
        
        self->_crossHairs.autoresizingMask = UIViewAutoresizingNone;
        
        UIColor *edgeColor = [UIColor colorWithWhite:1 alpha:1];
        
        self->_crossHairs.layer.cornerRadius = NKOPickerViewCrossHairsWidthAndHeight/2;
        self->_crossHairs.layer.borderColor = edgeColor.CGColor;
        self->_crossHairs.layer.borderWidth = 4;
        self->_crossHairs.layer.shadowColor = [UIColor blackColor].CGColor;
        self->_crossHairs.layer.shadowOffset = CGSizeMake(0, 1);
        self->_crossHairs.layer.shadowRadius = 1;
        self->_crossHairs.layer.shadowOpacity = 0.5f;
        
    }
    
    if (self->_crossHairs.superview == nil){
        [self insertSubview:self->_crossHairs aboveSubview:self.hueSatImage];
    }
    
    return self->_crossHairs;
}

- (UIImageView*)brightnessIndicator {
    
    if (self->_brightnessIndicator == nil){
        self->_brightnessIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.gradientView.frame)*0.5f,
                                                                                   CGRectGetMinY(self.gradientView.frame)-4,
                                                                                   NKOPickerViewBrightnessIndicatorWidthAndHeight,
                                                                                   NKOPickerViewBrightnessIndicatorWidthAndHeight)];
        
        self->_brightnessIndicator.autoresizingMask = UIViewAutoresizingNone;
        self->_brightnessIndicator.backgroundColor = [UIColor whiteColor];
        _brightnessIndicator.layer.cornerRadius = NKOPickerViewBrightnessIndicatorWidthAndHeight/2;
        _brightnessIndicator.layer.shadowColor = [UIColor blackColor].CGColor;
        _brightnessIndicator.layer.shadowOffset = CGSizeMake(0, 1);
        _brightnessIndicator.layer.shadowRadius = 1;
        _brightnessIndicator.layer.shadowOpacity = 0.5f;
    }
    
    if (self->_brightnessIndicator.superview == nil){
        [self insertSubview:self->_brightnessIndicator aboveSubview:self.gradientView];
    }
    
    return self->_brightnessIndicator;
}

@end


// NKOBrightnessView
@interface NKOBrightnessView() {
    CGGradientRef gradient;
}

@end

@implementation NKOBrightnessView

- (void)setColor:(UIColor*)color {
    
    if (self->_color != color) {
        self->_color = [color copy];
        [self setupGradient];
        
        [self setNeedsDisplay];
    }
}

- (void)setupGradient {
    
    const CGFloat *c = CGColorGetComponents(self.color.CGColor);
    
    CGFloat colors[] = {
        c[0], c[1], c[2], 1.0f,
        0.f, 0.f, 0.f, 1.f,
    };
    
    CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();
    
    if (gradient != nil){
        CGGradientRelease(gradient);
    }
    
    gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, sizeof(colors)/(sizeof(colors[0])*4));
    CGColorSpaceRelease(rgb);
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect clippingRect = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    
    CGPoint endPoints[] = {
        CGPointMake(0,0),
        CGPointMake(self.frame.size.width,0),
    };
    
    CGContextSaveGState(context);
    CGContextClipToRect(context, clippingRect);
    
    CGContextDrawLinearGradient(context, gradient, endPoints[0], endPoints[1], 0);
    CGContextRestoreGState(context);
}

- (void)dealloc {
    CGGradientRelease(gradient);
}

@end


//UIImage category
@implementation UIImage(NKO)

- (UIImage*)nko_tintImageWithColor:(UIColor*)tintColor {
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, area, self.CGImage);
    [tintColor set];
    CGContextFillRect(ctx, area);
    CGContextRestoreGState(ctx);
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    CGContextDrawImage(ctx, area, self.CGImage);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
