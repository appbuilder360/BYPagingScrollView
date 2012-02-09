//
// Displays text with Zoom support.
//

@interface TextScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, readonly) UILabel *textLabel;
@property (nonatomic, copy) NSString *text;

@end
