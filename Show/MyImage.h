#import "Base.h"


// Class that holds an image read from a PNG

@interface MyImage : NSObject

// Factory constructor
//  > filename of .png
+(MyImage *) read: (const char *)filename;


// Get the OpenGL texture id assigned to this image;
// if none has been assigned yet, do so
-(int) textureId;

// Delete the OpenGL texture assigned to this image (if any)
-(void) freeTexture;

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSString *filename;

// Size of texture containing this image (it may have been padded
// to the right and above to become a power of 2 in both dimensions)
@property (nonatomic) IPoint2 texSize;

// Get the size of the image content (may differ from the size of the texture
// that contains it)
@property (nonatomic, readonly) IPoint2 sizeInPixels;

@end

