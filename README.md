# BYPagingScrollView

This Demo project introduces a component `BYPagingScrollView` intended to simplify implementation of the paging `UIScrollView`. `BYPagingScrollView` has a simple API similar to the `UITableView`'s.

# Requirements

Xcode 4.2, iOS 4.0

# How to integrate

* Import `BYPagingScrollView.h` and `BYPagingScrollView.m` into your project.

* Create a control in the view controller and define the `pageSource`.

Code:

    - (void)viewDidLoad
    {
        [super viewDidLoad];
    
        CGRect pagingRect = CGRectInset(self.view.bounds, - DEFAULT_GAP_BETWEEN_PAGES / 2, 0);
        BYPagingScrollView pagingScrollView = [[BYPagingScrollView alloc] initWithFrame:pagingRect];
        pagingScrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        pagingScrollView.pageSource = self;

        [self.view addSubview:pagingScrollView];
        [pagingScrollView release];
    }

* Page source should provide the number of pages and a view for each page. Page views can be reused by their class names.

Code:

    - (NSUInteger)numberOfPagesInScrollView:(BYPagingScrollView *)scrollView
    {
        return 10; // 10 pages with text 1, 2, 3 .. 10
    }
    
    - (UIView *)scrollView:(BYPagingScrollView *)scrollView viewForPageAtIndex:(NSUInteger)pageIndex
    {
        UILabel *label = [scrollView dequeReusablePageViewWithClassName:NSStringFromClass([UILabel class])];
        if (label == nil) {
            label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
            label.contentMode = UIViewContentModeCenter;
            label.textAlignment = UITextAlignmentCenter;
            label.font = [UIFont boldSystemFontOfSize:100];
            label.textColor = [UIColor colorWithWhite:.45 alpha:1];
            label.backgroundColor = [UIColor colorWithWhite:.75 alpha:1];
        }
        label.text = [NSString stringWithFormat:@"%d", pageIndex + 1];
        return label;
    }

# License

`BYPagingScrollView` is licensed under the BSD license.