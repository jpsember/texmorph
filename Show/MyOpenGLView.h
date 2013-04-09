/*
    UIView subclass for performing OpenGL rendering
*/

/* You must add some additional frameworks to your project or
   you'll get a lot of linker errors.
   
   In particular, you need:
 
        OpenGLES.framework
        QuartzCore.framework
 
    It's simplest to drag and drop these from another Xcode project.
 */

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "Base.h"

void deleteTexture(int texHandle);

@interface MyOpenGLView : UIView

@property (readonly, nonatomic) BOOL animating;
@property (nonatomic) int animationFrameInterval;

- (void)touchLoc:(NSSet *)touches   : (int *)tapCount : (IPoint2 *)loc;
- (id) initWithFrame: (CGRect) bounds;
- (void) plotFrame;
- (void)startAnimation;
- (void)stopAnimation;
@end



typedef struct {
	int renderState;
	int glInitialized;
	int activeTexture_;
	bool glActive_;
	bool textureMode_;
	bool projectionPrepared;
    float scaleFactor_;
	FlPoint3 focus_;
    
	IRect viewBounds;

	// Android OpenGL doesn't seem to want to read back values (viewport, matrices);
	// store them here instead.
	IRect viewport;
} ScreenVars;

extern ScreenVars TF;

/*
 * Render states.
 * Used to avoid making unnecessary OGL state calls.
 */
enum {
	RENDER_UNDEFINED, RENDER_RGB, RENDER_SPRITE,
    RENDER_SPRITE_NOVBO, // used only in debug, if using Vertex Buffer Objects
	RENDER_TOTAL
};
// Determine if OpenGL context is active.
bool glActive();

/*
 * Initialize OpenGL state for our purposes;
 * called at start of application
 * > immediate : true to it immediately
 */
void initializeOpenGL(bool immediate);

void selectTexture(int texHandle);
void setTintMode(bool f);
void setRenderState(int state);
void deleteBuffer(int bufferId);

void setFocus(const IPoint2 &focus);
float scaleFactor();
void setScaleFactor(float f);

const FlPoint3 &getFocus();

void glTranslate(const FlPoint2 &pt, bool neg = false);
void prepareProjection();
