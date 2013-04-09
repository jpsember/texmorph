#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "MyOpenGLView.h"

void paintGL();


@interface MyOpenGLView()
{
	
	EAGLContext *context;
	
	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
	GLuint viewRenderbuffer, viewFramebuffer;
	
	/* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
	GLuint depthRenderbuffer;
	
	int animationFrameInterval;
    
    NSTimer *animationTimer;
}

- (void)createFramebuffer;
- (void)destroyFramebuffer;
- (void)processFrame;

@end


@implementation MyOpenGLView

@dynamic animationFrameInterval;

- (void)touchLoc:(NSSet *)touches   : (int *)tapCount : (IPoint2 *)loc {
	UITouch *touch = [touches anyObject];
	ASSERT(touch != nil);
	
	if (tapCount) {
		*tapCount = [touch tapCount];
	}
	CGPoint pt = [touch locationInView: self];
    
    loc->setTo(pt.x,pt.y);
}


+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithFrame: (CGRect) bounds
{
    //DBGWARN
    
    self = [super initWithFrame: bounds];
    ASSERT(self);
    
    CGRect  rect = [[UIScreen mainScreen] bounds];
    
     
    [self setBounds: rect];
    [self setCenter:  CGPointMake(rect.size.width/2,rect.size.height/2)];
    
    // Get the layer
    CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
    
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    ASSERT(context);
    bool flag = [EAGLContext setCurrentContext:context];
    ASSERT(flag);
    [self createFramebuffer];
    
    _animating = FALSE;
    animationFrameInterval = 1;
    animationTimer = nil;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone         ];
    
    pr(" done init\n");
	
    
	return self;
}

- (void)layoutSubviews
{
    //    DBGWARN
    pr("layoutSubviews\n");
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
}


- (void)createFramebuffer
{
    //    DBGWARN
    pr("createFramebuffer\n");
    
    viewFramebuffer = 0;
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
    
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	bool valid = (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) == GL_FRAMEBUFFER_COMPLETE_OES);
    ASSERT(valid);
}


- (void)destroyFramebuffer
{
    
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}


- (int) animationFrameInterval
{
	return animationFrameInterval;
}


- (void) startAnimation
{
	if (!self.animating)
	{
        animationTimer = [NSTimer scheduledTimerWithTimeInterval:
                          (NSTimeInterval)((1.0 / FPS) * animationFrameInterval)
                                                          target:self
                                                        selector:@selector(processFrame)
                                                        userInfo:nil repeats:TRUE];
		
		_animating = TRUE;
	}
}

- (void)stopAnimation
{
	if (_animating)
	{
        [animationTimer invalidate];
        animationTimer = nil;
		_animating = FALSE;
	}
}



// Release resources when they are no longer needed.
- (void)dealloc
{
	if([EAGLContext currentContext] == context) {
		[EAGLContext setCurrentContext:nil];
	}
	
	[context release];
	context = nil;
	
	[super dealloc];
}

- (void) plotFrame
{
    warn("...override plotFrame method");
}


// ---------------------------------------
// Timer-based logic and drawing
// ---------------------------------------
- (void)processFrame
{
    @autoreleasepool {
        
    // Make sure that you are drawing to the current context
    [EAGLContext setCurrentContext:context];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    
    paintGL();
    
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
    }
}

// ---------------------------------------
// Mouse input
// ---------------------------------------

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    IPoint2 pt;
    [self touchLoc: touches : nil : &pt];
    IPoint2 uipt;
    
    unimp("touches began");
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    IPoint2 pt;
    [self touchLoc: touches : nil : &pt];
    IPoint2 uipt;
}

-(void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    IPoint2 pt;
    [self touchLoc: touches : nil : &pt];
    IPoint2 uipt;
}
@end




ScreenVars TF;

static bool glInitialized;

Color bgndColor(0, 0, 0, 1.0f);

static void texturesOn() {
    if (!TF.textureMode_) {
        glEnable(GL_TEXTURE_2D);
        TF.textureMode_ = true;
    }
}

static void texturesOff() {
    if (TF.textureMode_) {
        glDisable(GL_TEXTURE_2D);
        TF.textureMode_ = false;
    }
}

void initializeOpenGL(bool immediate) {
    
    pr("initializeOpenGL immediate=%d glInitialized=%d\n",immediate,glInitialized);
    
    if (!immediate) {
        glInitialized = false;
        return;
    }
    
    // use flat shading
    glShadeModel(GL_FLAT);
    
    // disable textures
    glDisable(GL_TEXTURE_2D);
    
    // specify color to clear screen to
    glClearColor(0, 0, 0, 1);
    
    // enable alpha channel in textures
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    
    FlRect bb = c([[UIScreen mainScreen] bounds]);
    
    TF.viewBounds = IRect(&bb);
    TF.scaleFactor_ = 1.0;
    glInitialized = true;
    
}

bool glActive() {
    return TF.glActive_;
}


void setRenderState(int state) {
    //DBGWARN
    ASSERT(state > RENDER_UNDEFINED && state < RENDER_TOTAL);
    
    ASSERT( glActive());
    
    bool changed = TF.renderState != state;
    
    // warn("always assuming render state changed");changed = true;
    
    if (changed) {
        pr("setRenderState from %d to %d\n",TF.renderState,state );
        
        //warn("always choosing RENDER_SPRITE");state=RENDER_SPRITE;
        TF.renderState = state;
        
        switch (TF.renderState) {
                
            case RENDER_SPRITE: {
                texturesOn();
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                glEnableClientState(GL_VERTEX_ARRAY);
            }
                break;
                
            case RENDER_SPRITE_NOVBO:
                glBindBuffer(GL_ARRAY_BUFFER, 0);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
                
                texturesOn();
                glEnableClientState(GL_VERTEX_ARRAY);
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                break;
                
            case RENDER_RGB:
                glBindBuffer(GL_ARRAY_BUFFER, 0);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
                texturesOff();
                glEnableClientState(GL_VERTEX_ARRAY);
                break;
        }
    }
}

void deleteTexture(int texHandle) {
    ADJALLOC("TEX",-1);
    
    // if we are shutting down the graphics (due to a PAUSE),
    // the OpenGL context might not be active; in this case, do nothing.
    //if (glActive())
    glDeleteTextures(1, (GLuint *) &texHandle);
}
void deleteBuffer(int bufferId) {
    // if we are shutting down the graphics (due to a PAUSE),
    // the OpenGL context might not be active; in this case, do nothing.
    glDeleteBuffers(1, (GLuint *) &bufferId);
    ADJALLOC("glbuffer",-1);
}
void selectTexture(int texHandle) {
    ASSERT(TF.textureMode_);
    
    if (TF.activeTexture_ != texHandle) {
        TF.activeTexture_ = texHandle;
        glBindTexture(GL_TEXTURE_2D, texHandle);
    }
}


void disposeAll() {
    TF.glInitialized = false;
}

static void paintStart() {
  // DBGWARN
    if (!TF.glInitialized) {
        
        // initialize OGL state
        TF.renderState = RENDER_UNDEFINED;
        TF.activeTexture_ = 0;
        
        TF.textureMode_ = false;
        
        TF.glInitialized = true;
    }
    
    // Clear the OpenGL view
    {
        const float *m;
        m = bgndColor.rgba();
        
        glClearColor(m[0], m[1], m[2], 1);
        
        //  glClearColor(.5f,.5f,.2f, 1);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    
    
    {
        // define the openGL viewport
        IRect &gv = TF.viewport;
        
        gv.setTo(TF.viewBounds);
        
        glViewport(gv.x, gv.y, gv.width, gv.height);
        
        { // fix texture coordinate problem, so (0,0) is lower left of png
            glMatrixMode(GL_TEXTURE);
            glLoadIdentity();
            glTranslatef(0, -1, 0);
            glScalef(1, -1, 1);
        }
        
    }
    
#if DEBUG
    TF.projectionPrepared = false;
#endif
    
}

void paintGL() {
    
    static int frameNumber;
    
#undef p2
#define p2(a) //{if ((frameNumber & 3) == 0) pr(a); }
    frameNumber++;
    
    TF.glActive_ = true;
    
    p2(("paintGL frame %d, glInitialized=%d\n",frameNumber,glInitialized));
    
    if (!glInitialized) {
        initializeOpenGL(true);
    }
    
    paintStart();
    
    [appView() plotFrame];
    TF.glActive_ = false;
}



#if DEBUG
const char *d(const Color &color) {
	char *s = debugStr();
	sprintf(s, "[%3.2f %3.2f %3.2f %3.2f]", color.red(), color.blue(),
			color.green(), color.alpha());
	return s;
}
#endif


static FlMatrix vs_matProj(4, 4);
static FlMatrix vs_matModelView(4, 4);

const FlPoint3 &getFocus() {
    return TF.focus_;
}

static bool tintMode;
void setTintMode(bool f) {
    
    if (tintMode != f || !TF.glInitialized) {
        tintMode = f;
        if (!tintMode) {
            glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
        } else {
            glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
        }
    }
}

// ----------------- Camera code ----------------------


void glTranslate(const FlPoint2 &pt, bool neg) {
    if (neg)
        glTranslatef(-pt.x, -pt.y, 0);
    else
        glTranslatef(pt.x, pt.y, 0);
}
float scaleFactor() {
    return TF.scaleFactor_;
}

void setScaleFactor(float f) {
    TF.scaleFactor_ = f;
}

void prepareProjection() {
    
    //DBGWARN
    
    ASSERT2(!TF.projectionPrepared,"projection already prepared");
    TF.projectionPrepared = true;
    
    FlMatrix &m = vs_matProj;
    
    // Construct projection matrix.
    // Perform same calculations as described in documentation
    // for glOrtho() to construct this matrix in v_matProj.
    {
        m.setToIdentity();
        float s = .5f / scaleFactor();
        
        float height = TF.viewBounds.height * s;
        float width = TF.viewBounds.width * s;
        
#undef M
#define M(row,col,val) m.set(row,col,val)
        M(0,0,1/width);
        M(1,1,1/height);
        M(2,2,-1);
    }
    
    // Construct modelview matrix.
    {
        FlMatrix &m = vs_matModelView;
        m.setToTranslate(-TF.focus_.x - TF.viewBounds.midX(),
                         -TF.focus_.y - TF.viewBounds.midY(),
                         -TF.focus_.z);
    }
    
    // ---------------------------------------------------------
    // prior to this point, no openGL context has been required.
    // ---------------------------------------------------------
    
    
    glMatrixMode(GL_PROJECTION);
    glLoadMatrixf(vs_matProj.c);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadMatrixf(vs_matModelView.c);
}

