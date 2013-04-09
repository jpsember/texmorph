
#import "Base.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        try {
            // The custom AppDelegate class must have the name "AppDelegate".
            return UIApplicationMain(argc, argv, nil, @"AppDelegate");
        } catch (MyException &e) {
            printf("Caught exception: %s\n",d(e));
        }
    }
}
