#import "TextScrollView.h"

@implementation TextScrollView

@synthesize textLabel = _textLabel;

#pragma mark -

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.showsVerticalScrollIndicator =
        self.showsHorizontalScrollIndicator = NO;
        self.delegate = self;
        self.bounces = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.contentSize = CGSizeMake(CGRectGetWidth(frame) * 4, CGRectGetHeight(frame) * 4);
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
        self.canCancelContentTouches = NO;
        
        _textLabel = [[UILabel alloc] initWithFrame:(CGRect){ CGPointZero, self.contentSize }];
        _textLabel.contentMode = UIViewContentModeCenter;
        _textLabel.backgroundColor = [UIColor colorWithWhite:.75 alpha:1];
        _textLabel.textAlignment = UITextAlignmentCenter;
        _textLabel.font = [UIFont boldSystemFontOfSize:100];
        _textLabel.textColor = [UIColor colorWithWhite:.45 alpha:1];
        [self addSubview:_textLabel];
        
        self.minimumZoomScale = 0.25;
        self.maximumZoomScale = 1.0;
        self.zoomScale = 0.25;
    }
    return self;
}

- (void)dealloc
{
    [_textLabel release];
    [super dealloc];
}

#pragma mark - Center content to improve user experience

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Center content in the scroll view
    CGSize scrollSize = self.frame.size;
    CGRect textRect = self.textLabel.frame;
    
    if (CGRectGetWidth(textRect) < scrollSize.width)
        textRect.origin.x = round((scrollSize.width - CGRectGetWidth(textRect)) / 2);
    else
        textRect.origin.x = 0;
    
    if (CGRectGetHeight(textRect) < scrollSize.height)
        textRect.origin.y = round((scrollSize.height - CGRectGetHeight(textRect)) / 2);
    else
        textRect.origin.y = 0;
    
    self.textLabel.frame = textRect;
}

#pragma mark - Zoom In and Out will be applied to the text view

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.textLabel;
}

#pragma mark - Text property is backed by the text layer's string

- (NSString *)text
{
    return self.textLabel.text;
}

- (void)setText:(NSString *)text
{
    self.zoomScale = 0.25;
    
    self.textLabel.text = text;
}

@end
