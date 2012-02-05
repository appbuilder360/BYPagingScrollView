#import "TextScrollView.h"

@implementation TextScrollView

@synthesize textView = _textView;
@synthesize textLayer = _textLayer;

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
        self.contentSize = frame.size;
        self.minimumZoomScale = .25;
        self.maximumZoomScale = 8;
        self.zoomScale = 1;
        self.backgroundColor = [UIColor blackColor];
        self.opaque = YES;
        self.canCancelContentTouches = NO;
        
        _textLayer = [[CATextLayer alloc] init];
        _textLayer.contentsGravity = kCAGravityCenter;
        _textLayer.alignmentMode = kCAAlignmentCenter;
        _textLayer.wrapped = YES;
        _textLayer.truncationMode = kCATruncationNone;
        _textLayer.string = @"ABCD";
        _textLayer.fontSize = 200;
        _textLayer.bounds = CGRectMake(0, 0, 500, 200);
        _textLayer.foregroundColor = [UIColor colorWithWhite:.45 alpha:1].CGColor;
        _textLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        
        _textView = [[UIView alloc] initWithFrame:self.bounds];
        _textView.contentMode = UIViewContentModeCenter;
        _textView.backgroundColor = [UIColor colorWithWhite:.75 alpha:1];
        [_textView.layer addSublayer:_textLayer];
        [self addSubview:_textView];
    }
    return self;
}

- (void)dealloc
{
    [_textView release];
    [_textLayer release];
    [super dealloc];
}

#pragma mark - Center content to improve user experience

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Center content in the scroll view
    CGSize scrollSize = self.frame.size;
    CGRect textRect = self.textView.frame;
    
    if (CGRectGetWidth(textRect) < scrollSize.width)
        textRect.origin.x = round((scrollSize.width - CGRectGetWidth(textRect)) / 2);
    else
        textRect.origin.x = 0;
    
    if (CGRectGetHeight(textRect) < scrollSize.height)
        textRect.origin.y = round((scrollSize.height - CGRectGetHeight(textRect)) / 2);
    else
        textRect.origin.y = 0;
    
    self.textView.frame = textRect;
}

#pragma mark - Zoom In and Out will be applied to the text view

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.textView;
}

#pragma mark - Redraw text after Zoom gesture

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    return;
    [CATransaction setDisableActions:YES];
    self.textLayer.contentsScale = scrollView.zoomScale;
    [CATransaction setDisableActions:NO];
}

#pragma mark - Text property is backed by the text layer's string

- (NSString *)text
{
    return self.textLayer.string;
}

- (void)setText:(NSString *)text
{
    [CATransaction setDisableActions:YES];
    self.textLayer.string = text;
    [CATransaction setDisableActions:NO];
}

@end
