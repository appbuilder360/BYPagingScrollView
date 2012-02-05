//
// Displays text with Zoom support.
//

@interface TextScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, readonly) UIView *textView;
@property (nonatomic, readonly) CATextLayer *textLayer;

@property (nonatomic, copy) NSString *text;

@end
