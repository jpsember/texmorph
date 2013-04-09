
// This structure holds a set of points defining the variable control points.
typedef Vector<FlPoint2> PtsVec;


#if 0
#define PAUSETIME 3
#define NFRAMES 3
#else
#define PAUSETIME ((int)(FPS * 2.2  ))
#define NFRAMES ((int) FPS * .5 )
#endif

#define STRETCHY .2f //.65f


// A set of control points
class CtrlSet{
public:
    CtrlSet(float *c = 0);
    ~CtrlSet();
     
    FlPoint2 *pts() {return pts_;}
    FlPoint2 &pt(int ind) {
        return pts_[ind];
    }
    
    CompiledSpriteSet *getSprites();
    
    /**
     Apply this set of control points to the mesh weights
     to construct a matrix of points defining a mesh
     > m  where to store the mesh points
     */
    void constructMesh(FlPoint2 *m);
    
    /**
     Get the basic (unperturbed) control point set
     */
    static CtrlSet &baseSet();
private:
    FlPoint2 *pts_; //[CTRL_POINTS];
    CompiledSpriteSet *ss;
};


/**
 Construct a random set of offsets for variable control points
 */
void rndCtrlPerturb(PtsVec &v);
/**
 Negate coordinates of a set of control points
 */
void pertNeg(PtsVec &v);
/**
 Apply a scaling factor to a set of control points
 */
void pertScale(PtsVec &vOrig, float scale, PtsVec &dest);
/**
 Construct a CtrlSet from a set of variable control points
 */
CtrlSet *csetFrom(PtsVec &pert);
/**
 Build the default set of variable control points (the points in their unperturbed positions)
 */
void buildBasePoints(PtsVec &dest);
void clearCtrlSetVector(Vector<CtrlSet *> &csets);
/**
 Build a set of CtrlSets to transition from a start to final variable control points configuration
 */
void buildCtrlSets(PtsVec &orig, PtsVec &dest, int nFrames, Vector<CtrlSet *> &csets);

