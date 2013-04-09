#import "MyImage.h"
#import "MyOpenGLView.h"


static int ceilingPower2(int n) {
	int k = 1;
	while (k < n) {
		k <<= 1;
	}
	return k;
}



// Define an anonymous category to add private ivars
 
@interface MyImage()
@property (nonatomic) int textureId;
@property (nonatomic) BOOL textureIdKnown;
@end


@implementation MyImage 

-(int) textureId {
    if (!self.textureIdKnown) {
       //  DBGWARN
        
        pr("get textureId\n"); 
        
        uint texId2;
        glGenTextures(1, &texId2);
        ADJALLOC("TEX",1);
        
        self.textureId = texId2;
        pr(" texId %d allocated\n",_textureId);
        
        UIImage *img = self.image;
        
        CGImageRef ci = img.CGImage;
        
        int w = CGImageGetWidth(ci);
        int h = CGImageGetHeight(ci);
        ASSERT(w <= 768 && h <= 1024);
        
        int n = (CGImageGetAlphaInfo(ci) == kCGImageAlphaNone) ? 3 : 4;
        
        pr(" w=%d h=%d n=%d\n",w,h,n);
        
        int tdLen = w*h*4;
        
        byte* textureData = (byte *)malloc(tdLen);
        ADJALLOC("malloc",1);
        pr(" alloc textureData buffer len %d at %p\n",tdLen,textureData);
        
        memset(textureData, 0, tdLen );
        
        CGContext* textureContext = CGBitmapContextCreate(textureData, w, h, 8, w * 4,
                                                          CGImageGetColorSpace(ci), kCGImageAlphaPremultipliedLast);
        CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, (CGFloat)w, (CGFloat)h), ci);
        CGContextRelease(textureContext);
        
        int *sourceImgData = (int *) textureData;
        
        IPoint2 imgSize =  self.sizeInPixels;
        
        bool hasAlpha = (n == 4);
        
        // pad out texture so both dimensions are powers of 2
        IPoint2 destImgSize(ceilingPower2(imgSize.x), ceilingPower2(imgSize.y));
        
        int pixelSize = hasAlpha ? 4 : 3;
        
        int bSize = destImgSize.x * destImgSize.y * pixelSize;
        
        byte *texBuff = (byte *)malloc(bSize);
        ADJALLOC("malloc", 1);
        pr(" alloc padded texture buffer len %d at %p\n",bSize,texBuff);
        
        int xPadding = destImgSize.x - imgSize.x;
        int yPadding = destImgSize.y - imgSize.y;
        
        self.texSize = destImgSize;
        
        
        int j = 0;
        for (int i = yPadding * destImgSize.x * pixelSize; i > 0; i--)
            texBuff[j++] = 0;
        
        //	pr(("installing texture, imgSize=%s\n",d(imgSize) ));
        
        int i = 0;
        int a = 0;
        for (int y = 0; y < imgSize.y; y++) {
            for (int x = 0; x < imgSize.x; x++) {
                int pix = sourceImgData[i++];
                
                int r = (pix & 0xff);
                pix >>= 8;
                int g = (pix & 0xff);
                pix >>= 8;
                int b = (pix & 0xff);
                if (hasAlpha) {
                    pix >>= 8;
                    a = (pix & 0xff);
                }
                texBuff[j++] = (byte) r;
                texBuff[j++] = (byte) g;
                texBuff[j++] = (byte) b;
                if (hasAlpha)
                    texBuff[j++] = (byte) a;
            }
            for (int x = xPadding * pixelSize; x > 0; x--)
                texBuff[j++] = 0;
        }
        ADJALLOC("malloc", 1);
        pr(" free textureData %p\n",textureData);
        
        free(textureData);
        ADJALLOC("malloc",-1);
        
        
        // bind this texture
        glBindTexture(GL_TEXTURE_2D, _textureId);
        
        // GL_NEAREST stops bleeding from neighboring pixels,
        // and scales things up looking blocky
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        
        // produce a texture from the byte buffer
        glTexImage2D(//
                     GL_TEXTURE_2D, // 2d textures
                     0, // level of detail
                     hasAlpha ? GL_RGBA : GL_RGB, // internal format
                     destImgSize.x, //
                     destImgSize.y, //
                     0, // no border
                     hasAlpha ? GL_RGBA : GL_RGB, // incoming pixel format: 4 bytes in RGBA order
                     GL_UNSIGNED_BYTE, // incoming pixel data type: unsigned bytes
                     texBuff // incoming pixels
                     );
        
        pr(" freeing texBuff %p\n",texBuff);
        
        free(texBuff);
        ADJALLOC("malloc",-1);
        
        pr(" returning textureId %d\n\n\n",_textureId);
        self.textureIdKnown = true;
    }
    
    return _textureId;
}

-(NSString *) description {
    char *s = debugStr();
    sprintf(s,"MyImage %s, img=%s\n",d(self.filename),d(self.image));
    return c(s);
}

-(void) dealloc
{
    [self freeTexture];
    rel(_image);
    rel(_filename);
    [super dealloc];
}

-(void) freeTexture {
//    DBGWARN
    
    if (self.textureIdKnown) {
        pr("freeing up texture id %d\n",_textureId);
        deleteTexture(_textureId);
        self.textureIdKnown = false;
    }
}


+(MyImage *) read: (const char *)filename
{
    MyImage *img = [[MyImage alloc] initWithFilename: filename];
    return img;
}

-(id) initWithFilename: (const char *) filename
{
    //DBGWARN
    pr("MyImage initWithFilename %s\n",filename);
    
    self = [super init];
    ASSERT(self);
    
    _filename = c(filename);
    
    FILE *f = my_fopen(filename, "rb");
    ASSERT(f);
    
    fseek(f, 0L, SEEK_END);
    int sz = ftell(f);
    fseek(f, 0L, SEEK_SET);
    pr(" length of file=%d\n",sz);
    
    // We'll pass this buffer to NSData, so we don't need to free it
    byte *by = (byte *)malloc(sz);
    ASSERT(by);
    
    int nr = fread(by, 1, sz, f);
    pr(" read %d bytes\n",nr);
    
    ASSERT(nr == sz);
    fclose(f);
    
    
    @autoreleasepool {
        NSData *dt = [NSData dataWithBytesNoCopy:by length:sz freeWhenDone:true];
        self.image = [[[UIImage alloc] initWithData: dt] autorelease];
    }
    

    return self;
}

-(IPoint2) sizeInPixels
{
    return c(self.image.size);
}

@end


