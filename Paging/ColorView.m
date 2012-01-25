#import "ColorView.h"

@implementation ColorView

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:CGRectInset(self.bounds, .5, .5)];
    [[UIColor whiteColor] setStroke];
    [bezierPath setLineWidth:2];
    [bezierPath stroke];
}

@end
