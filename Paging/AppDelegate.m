#import "AppDelegate.h"
#import "PagingViewController.h"

@implementation AppDelegate

@synthesize window = _window;

#pragma mark -

- (void)dealloc
{
    [_window release];
    
    [super dealloc];
}

#pragma mark - Create user interface after application launch

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIViewController *viewController = [[[PagingViewController alloc] initWithNibName:nil bundle:nil] autorelease];
    UINavigationController *navigationController = [[[UINavigationController alloc] initWithRootViewController:viewController] autorelease];
    navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    
    self.window = [[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
