//
//  XHScrollMenu.m
//  XHScrollMenu
//
//  Created by 曾 宪华 on 14-3-8.
//  Copyright (c) 2014年 曾宪华 QQ群: (142557668) QQ:543413507  Gmail:xhzengAIB@gmail.com. All rights reserved.
//

#import "XHScrollMenu.h"

#import "UIScrollView+XHVisibleCenterScroll.h"

#define kXHMenuButtonBaseTag 100

@interface XHScrollMenu () <UIScrollViewDelegate> {
    NSUInteger _currentSelectedIndex;
}

@property (nonatomic, strong) UIView *leftShadowView;
@property (nonatomic, strong) UIView *rightShadowView;

@property (nonatomic, strong) UIButton *managerMenusButton;

@property (nonatomic, strong) NSMutableArray *menuButtons;

@end

@implementation XHScrollMenu

- (void)managerMenusButtonClicked:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(scrollMenuDidManagerSelected:)]) {
        [self.delegate scrollMenuDidManagerSelected:self];
    }
}

- (void)menuButtonSelected:(UIButton *)sender {
    _currentSelectedIndex = sender.tag - kXHMenuButtonBaseTag;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self.scrollView scrollRectToVisibleCenteredOn:sender.frame animated:NO];
    } completion:^(BOOL finished) {
        [self setupIndicatorFrame:sender.frame animated:YES];
    }];
}

- (NSMutableArray *)menuButtons {
    if (!_menuButtons) {
        _menuButtons = [[NSMutableArray alloc] initWithCapacity:self.menus.count];
    }
    return _menuButtons;
}

- (UIView *)getShadowView:(BOOL)isLeft {
    UIView *shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, CGRectGetHeight(self.bounds))];
    shadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    shadowView.layer.shadowOffset = CGSizeMake((isLeft ? 2.5 : -1.5), 0);
    shadowView.layer.shadowRadius = 3.2;
    shadowView.layer.shadowOpacity = 0.5;
    shadowView.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowView.bounds].CGPath;
    shadowView.hidden = isLeft;
    shadowView.backgroundColor = self.backgroundColor;
    return shadowView;
}

- (void)setup {
    self.defaultSelectIndex = 0;
    
    _leftShadowView = [self getShadowView:YES];
    
    _rightShadowView = [self getShadowView:NO];
    
    
    CGFloat width = CGRectGetHeight(self.bounds);
    _managerMenusButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - width, 0, width, width)];
    _managerMenusButton.backgroundColor = self.backgroundColor;
    [_managerMenusButton addTarget:self action:@selector(managerMenusButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    CGRect rightShadowViewFrame = _rightShadowView.frame;
    rightShadowViewFrame.origin = CGPointMake(CGRectGetMinX(_managerMenusButton.frame) - CGRectGetWidth(rightShadowViewFrame), 0);
    _rightShadowView.frame = rightShadowViewFrame;
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_leftShadowView.frame), 0, CGRectGetWidth(self.bounds) - CGRectGetWidth(rightShadowViewFrame) * 2 - CGRectGetWidth(_managerMenusButton.frame), CGRectGetHeight(self.bounds))];
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.delegate = self;
    
    _indicatorView = [XHIndicatorView initIndicatorView];
    _indicatorView.alpha = 0.;
    [_scrollView addSubview:self.indicatorView];
    
    [self addSubview:self.scrollView];
    [self addSubview:self.leftShadowView];
    [self addSubview:self.rightShadowView];
    [self addSubview:self.managerMenusButton];
}

- (void)setupIndicatorFrame:(CGRect)menuButtonFrame animated:(BOOL)animated {
    [UIView animateWithDuration:(animated ? 0.15 : 0) delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        _indicatorView.frame = CGRectMake(CGRectGetMinX(menuButtonFrame), CGRectGetHeight(self.bounds) - kXHIndicatorViewHeight, CGRectGetWidth(menuButtonFrame), kXHIndicatorViewHeight);
    } completion:^(BOOL finished) {
        if ([self.delegate respondsToSelector:@selector(scrollMenuDidSelected:menuIndex:)]) {
            [self.delegate scrollMenuDidSelected:self menuIndex:_currentSelectedIndex];
        }
    }];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}

- (UIButton *)getButtonWithMenu:(XHMenu *)menu {
    CGSize buttonSize = [menu.title sizeWithFont:menu.titleFont constrainedToSize:CGSizeMake(MAXFLOAT, CGRectGetHeight(self.bounds) - 10) lineBreakMode:NSLineBreakByCharWrapping];
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonSize.width, buttonSize.height)];
    button.titleLabel.textAlignment = UITextAlignmentCenter;
    button.titleLabel.font = menu.titleFont;
    [button setTitle:menu.title forState:UIControlStateNormal];
    [button setTitle:menu.title forState:UIControlStateHighlighted];
    [button setTitle:menu.title forState:UIControlStateSelected];
    [button setTitleColor:menu.titleColor forState:UIControlStateNormal];
    [button setTitleColor:menu.titleColor forState:UIControlStateHighlighted];
    [button setTitleColor:menu.titleColor forState:UIControlStateSelected];
    [button addTarget:self action:@selector(menuButtonSelected:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)reloadData {
    // layout subViews
    CGFloat contentWidth = 10;
    for (XHMenu *menu in self.menus) {
        NSUInteger index = [self.menus indexOfObject:menu];
        UIButton *menuButton = [self getButtonWithMenu:menu];
        menuButton.tag = kXHMenuButtonBaseTag + index;
        CGRect menuButtonFrame = menuButton.frame;
        CGFloat buttonX = 0;
        if (index) {
            buttonX = kXHMenuButtonPaddingX + CGRectGetMaxX(((UIButton *)(self.menuButtons[index - 1])).frame);
        } else {
            buttonX = kXHMenuButtonStarX;
        }
        
        menuButtonFrame.origin = CGPointMake(buttonX, CGRectGetMidY(self.bounds) - (CGRectGetHeight(menuButtonFrame) / 2.0));
        menuButton.frame = menuButtonFrame;
        [self.scrollView addSubview:menuButton];
        [self.menuButtons addObject:menuButton];
        
        // scrollView content size width
        if (index == self.menus.count - 1) {
            contentWidth += CGRectGetMaxX(menuButtonFrame);
        }
        
        // indicator
        if (self.defaultSelectIndex == index) {
            _indicatorView.alpha = 1.;
            [self setupIndicatorFrame:menuButtonFrame animated:NO];
        }
    }
    [self.scrollView setContentSize:CGSizeMake(contentWidth, CGRectGetHeight(self.scrollView.frame))];
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat contentOffsetX = scrollView.contentOffset.x;
    if (scrollView.contentSize.width == CGRectGetWidth(scrollView.frame)) {
        self.leftShadowView.hidden = YES;
        self.rightShadowView.hidden = YES;
    } else if (scrollView.contentSize.width <= CGRectGetWidth(scrollView.frame)) {
        self.leftShadowView.hidden = YES;
        self.rightShadowView.hidden = YES;
    } else {
        if (contentOffsetX > 0) {
            self.leftShadowView.hidden = NO;
        } else {
            self.leftShadowView.hidden = YES;
        }
        
        if ((contentOffsetX + CGRectGetWidth(scrollView.frame)) >= scrollView.contentSize.width) {
            self.rightShadowView.hidden = YES;
        } else {
            self.rightShadowView.hidden = NO;
        }
    }
}

@end