#import "Base.h"

#import "MyOpenGLView.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (retain, nonatomic) UIWindow *window;
@property (nonatomic) bool started;
@end


@implementation AppDelegate

- (void)dealloc
{
    rel(_window);
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //DBGWARN
    
    pr("appDidFinishLaunching with options: %s\n",d(launchOptions));
 
    // Construct app window
    
    CGRect bnd = [[UIScreen mainScreen] bounds];
    UIWindow *w = [[[UIWindow alloc] initWithFrame:bnd] autorelease];
    w.backgroundColor = [UIColor whiteColor];
    self.window = w;
    
    // Construct a view for it; this will be considered the app's main view
    
    [w addSubview: appView()];
    [w makeKeyAndVisible];
    [w layoutSubviews];
    
    return YES;
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
//    DBG
    pr("applicationDidBecomeActive: %p\n",application);
    [appView() startAnimation];
    self.started = true;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
//    DBG
    
    pr("applicationWillTerminate: %p\n",application);
    if (self.started) {
        [appView() stopAnimation];
        self.started = false;
    }
}


- (void)applicationWillResignActive:(UIApplication *)application
{
//    DBG
    
    if (self.started) {
        [appView() stopAnimation];
        self.started = false;
    }
}
@end
