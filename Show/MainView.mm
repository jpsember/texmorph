#import "MyImage.h"
#import "MyOpenGLView.h"
#import "Sprite.h"
#import "CtrlSet.h"

static const char *imgNames[] = {
    "grad", "cheetah","diver", "elephant", "planet", "santorini",
    "waterfall","dino","seawall","lois","dylan",
    0
};

static int nImages() {
    static int nimg;
    if (!nimg) {
        while (imgNames[nimg])
            nimg++;
    }
    return nimg;
}

enum {
    ST_INIT,
    ST_PAUSING,
    ST_MORPHING,
};

@interface MainView: MyOpenGLView
@property (nonatomic, retain) MyImage *image;
@property (nonatomic) bool paused, nextPaused, testFocus;
@property (nonatomic) int state, time;
@end

@implementation MainView
{
    // Indexes of the two images being animated [0:leaving 1:entering]; -1 if none
    int _currentImageNumbers[2];
    
    MyImage *_images[2];
    
    // The control point sets being used to animate them
    Vector<CtrlSet *> *_csetsp[2];
}

-(void) setState: (int) newState
{
    if (_state != newState) {
        _state = newState;
        self.time = 0;
    }
}

-(void) dealloc
{
    for (int i = 0; i < 2; i++) {
        if (_csetsp[i]) {
            clearCtrlSetVector(*_csetsp[i]);
            del(_csetsp[i]);
        }
    }
    [super dealloc];
}

-(MyImage *)loadImage: (const char *)imgName
{
    String s(imgName);
    s.append(".jpg");
    return [MyImage read: s.c_str()];
}


-(id) initWithFrame: (CGRect) bounds
{
    for (int i = 0; i < 2; i++)
        newobj(_csetsp[i] ,Vector<CtrlSet *>);
    
    self = [super initWithFrame: bounds];
    ASSERT(self);
    
    [self startAnimation];
    return self;
}

/*
 Calculate transformation to fit one rectangle (a) into another (b);
 allow (a) to lie partly outside (b) to avoid too much letterboxing
 
 > a,b
 < offset location of transformed origin of (a)
 < scale scale factor to apply to vertices of (a)
 */
void fitRectWithinRect(IRect a, IRect b, FlPoint2 &offset, float &scale) {
    //DBGWARN
    
    float r1 = b.width / (float)a.width;
    float r2 = b.height / (float)a.height;
    
    float s1 = min(r1,r2);
    float s2 = max(r1,r2);
    float s = min(s1 * 1.8f, s2);
    pr("fitrr a=%s b=%s s1=%s s2=%s s=%s\n",d(a),d(b),d(s1),d(s2),d(s));
    
    scale = s;
    
    
    offset.x = (b.width - (a.width * scale))/2;
    offset.y = (b.height - (a.height * scale))/2;
    
    offset.x = (b.width - (a.width * scale))/2;
    offset.y = (b.height - (a.height * scale))/2;
}



-(void) chooseMorphPatterns
{
    // choose a morph pattern for both
    PtsVec pv;
    rndCtrlPerturb(pv);
    PtsVec pv2 = pv;
    pertNeg(pv2);
    
    PtsVec base;
    buildBasePoints(base);
    buildCtrlSets(base,pv, NFRAMES, *_csetsp[0]);
    buildCtrlSets(pv2,base, NFRAMES, *_csetsp[1]);
}

- (void) prepImage: (int) imageNumber toSlot: (int) slot
{
    rel(_images[slot]);
    _images[slot] = [[self loadImage: imgNames[imageNumber]] retain];
    _currentImageNumbers[slot] = imageNumber;
}

- (void) plotFrame
{
    if (!_paused)
        switch (self.state) {
            case ST_INIT:
            {
                srand((int)CACurrentMediaTime());
                
                _currentImageNumbers[0] = -1;
                [self prepImage: rand()%nImages() toSlot: 1];
                
                // build a static control set initially, since we haven't
                // chosenthat doesn't animate
                [self chooseMorphPatterns];
                self.state = ST_PAUSING;
                _time = max(1,PAUSETIME / 2);
            }
                break;
            case ST_PAUSING:
                if (_time == PAUSETIME) {
                    int a0 = _currentImageNumbers[1];
                    int a1;
                    do {
                        a1 = rand() % nImages();
                    } while (
                             a1 == a0
                             || (a1 == 0 && rand() % 8 != 3)
                             );
                    
                    // Shift image from slot 1 to slot 0
                    {
                        rel(_images[0]);
                        _images[0] = [_images[1] retain];
                        
                        _currentImageNumbers[0] = a0;
                    }
                    
                    [self prepImage:a1  toSlot:1];
                    
                    [self chooseMorphPatterns];
                    
                    self.state = ST_MORPHING;
                }
                break;
            case ST_MORPHING:
                if (_time == NFRAMES) {
                    self.state = ST_PAUSING;
                }
                break;
        }
    
    TF.focus_.setTo(0,0,0);
    
    float sclAdjust = 1;
//    sclAdjust = self.paused || self.nextPaused? .95 : 1;
    
    setScaleFactor(sclAdjust);
    
    if (self.testFocus) {
        TF.focus_.setTo(300,500,0);
        setScaleFactor(.3 * sclAdjust);
    }
    
	prepareProjection();
    
    
    for (int pass = 0; pass < 2; pass++) {
        
        if (pass == 0 && self.state != ST_MORPHING)
            continue;
        
        MyImage *img = _images[pass];
        // If just starting, there may be no image in this slot yet
        if (!img)
            continue;
        
        // Fill view with texture
        int texHandle = [img textureId];
        
        FlPoint2 vb(self.bounds.size.width, self.bounds.size.height);
        
        IPoint2 imgSize = img.sizeInPixels;
        IRect aR = IRect(0,0,imgSize.x,imgSize.y);
        IRect bR = IRect(0,0,vb.x,vb.y);
        
        
        // Determine the model transformation to fit the image into the view
        
        FlPoint2 offset;
        float scale;
        fitRectWithinRect(aR, bR, offset, scale);
        
        glPushMatrix();
        glTranslatef(offset.x,offset.y,0);
        glScalef(imgSize.x * scale,  imgSize.y * scale,1);
        
        glMatrixMode(GL_TEXTURE);
        glPushMatrix();
        glScalef(imgSize.x / (float)img.texSize.x,  imgSize.y / (float)img.texSize.y,1);
        
        
        int fm = NFRAMES-1;
        if (self.state == ST_MORPHING)
            fm = _time;
        fm = min(fm,NFRAMES-1);
        
        CtrlSet *cs = (*_csetsp[pass])[fm];
        
        
        
        float alph = 1;
        // The lower image can be opaque, as it will be replaced
        // as the upper image's alpha increases
        if (self.state == ST_MORPHING && pass == 1)
            alph =  (fm / (float)NFRAMES);
        
        if (alph < 1) {
            glEnable(GL_BLEND);
            
            glColor4f(1,1,1,alph);
            glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        }
        
        cs->getSprites()->render(texHandle);
        
        if (alph < 1) {
            glDisable(GL_BLEND);
            glColor4f(1.0f,1.0f,1.0f,1.0f); // go back to normal
        }
        
        glPopMatrix();
        glMatrixMode(GL_MODELVIEW);
        glPopMatrix();
    }
    if (!_paused) {
        self.time++;
        self.paused = self.nextPaused;
        self.nextPaused = false;
    }
    
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    IPoint2 pt;
    [self touchLoc: touches : nil : &pt];
    
    IRect bnd = ci([self bounds]);
    
    int slot = (pt.y / (bnd.width/3)) * 2 + (pt.x / (bnd.height/ 2));
    
    switch (slot) {
        case 0:
            if (self.paused || self.state == ST_MORPHING) {
                self.paused ^= true;
                self.nextPaused = false;}
            
            break;
        case 1:
            if (self.paused || self.state == ST_MORPHING) {
                self.paused ^= true;
                self.nextPaused = (self.state == ST_MORPHING);
            }
            break;
        case 2:
            showMeshMode ^= true;
            [self go];
            break;
        case 3:
            self.testFocus ^= true;
            break;
        case 4:
            [self go];
            
            break;
            
    }
}

// Turn off pausing, and if in ST_PAUSING, jump immediately to MORPHING
-(void) go {
    self.paused = false;
    if (self.state == ST_PAUSING) {
        self.time = PAUSETIME-1;
    }
}
@end


// Every application must provide this function to construct a 'main' application view
id appView( ) {
    static id appView;
    if (!appView) {
        CGRect bnd = [[UIScreen mainScreen] bounds];
        
        appView = [[MainView alloc] initWithFrame:bnd];
        
        [appView setBackgroundColor:c(Color(0,0,0))];
    }
    return appView;
}
