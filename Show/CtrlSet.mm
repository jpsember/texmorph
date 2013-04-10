#import "MyOpenGLView.h"
#import "Sprite.h"
#import "CtrlSet.h"

#define MESH_X  25
#define MESH_Y MESH_X
#define MESH_PTS (MESH_X * MESH_Y)

#define SHOW_MESH 0


#define CPTS 4


// Weights for each control point, for each vertex in mesh
static float meshWeights[MESH_PTS * CPTS];

// Texture coordinates for each vertex in mesh
// (These don't change; they're simply a grid overlaid on a square (0,0 --> 1,1))
static FlPoint2 texCoords[MESH_PTS];

static void calcEdgePt(float px, float py, int objIndex, FlPoint2 &dest) {
    dest.setTo(px,py);
    
    switch (objIndex - CPTS) {
        default : //0:
            dest.x = 0;
            break;
        case 1:
            dest.y = 0;
            break;
        case 2:
            dest.x = 1;
            break;
        case 3:
            dest.y = 1;
            break;
    }
}

static void calcMeshWeights() {
    
    float *mw = meshWeights;
    //DBGWARN
    
    for (int y = 0 ; y < MESH_Y; y++) {
        float cy = y / (float) (MESH_Y-1) ;
        for (int x = 0;  x <  MESH_X; x++) {
            float cx = x / (float)(MESH_X-1);
            
            float distSum = 0;
            
            for (int p = 0; p < 4+CPTS; p++) {
                FlPoint2 *pt;
                if (p < CPTS)
                    pt = &CtrlSet::baseSet().pt(p);
                else {
                    static FlPoint2 work;
                    calcEdgePt(cx,cy, p, work);
                    pt = &work;
                }
                float dx = pt->x - cx;
                float dy = pt->y - cy;
                float dist;
                
                dist = 1 / (1e-7f + dx*dx + dy * dy);

                  
                if (p < CPTS) {
                 
                    // Give more weight to control points vs walls (the
                    // weight gets very large as we get close to a wall, so
                    // we can add lots of weight)
                    
                    mw[p] = dist * 3;
                }
                
                distSum += dist;
            }
            pr("d%7.2f:",distSum);
            
            for (int p = 0; p < CPTS; p++) {
                pr("%5.2f:",mw[p]);
                mw[p] /= distSum;
                pr("%2.2f ",mw[p]);
            }
            pr("  ");
            
            {
                int ti = (y * MESH_X + x);
                texCoords[ti] = FlPoint2(cx,cy);
            }
            mw += CPTS;
            
        }
        pr("\n");
    }
}



// Default control points
#define PA (1 / 3.0f)
#define PB (1 - PA)

static float bs[] = {
   PA,PA,PB,PA,PB,PB,PA,PB, 
};

/**
 Get the basic (unperturbed) control point set
 */
CtrlSet &CtrlSet::baseSet() {
    static CtrlSet b;
    return b;
}

CtrlSet::CtrlSet(float *c) {
    if (!c)
        c = bs;
    ss = 0;
    pts_ = new FlPoint2[CPTS];
    for (int i = 0; i < CPTS; i++) {
        pt(i).setTo(c[i*2],c[i*2+1]);
    }
}
CtrlSet:: ~CtrlSet() {
    delete [] pts_;
    
    if (ss)
        del(ss);
}

void CtrlSet::constructMesh(FlPoint2 *m) {
    //        DBGWARN
    pr("\n\nconstructMesh\n");
    
    // Determine the offsets of these control points from the base values

    FlPoint2 cpt_offsets[CPTS];
    
    for (int j = 0; j < CPTS; j++) {
        FlPoint2 &basePt = baseSet().pt(j);
        FlPoint2 &cpt = pt(j);
        
        cpt_offsets[j].setTo(cpt.x - basePt.x, cpt.y - basePt.y);
    }
    
    for (int y = 0; y < MESH_Y; y++) {
        for (int x = 0; x < MESH_X; x++) {
            int i = y*MESH_X + x;
            
            float px = x / (float)(MESH_X-1);
            float py = y / (float)(MESH_Y-1);
            
            // Start with the base set's point,
            // then perturb it by the weighted perturbations of the control points
            
            for (int j = 0; j < CPTS; j++) {
                float wt = meshWeights[(i*CPTS + j)];
                FlPoint2 &cptOffset = cpt_offsets[j];
                
                px += cptOffset.x * wt;
                py += cptOffset.y * wt;
            }
            m[i].setTo(px,py);
            pr(" set mesh point %d,%d to %s\n",x,y,d(m[i]));
        }
        pr("\n");
    }
}

CompiledSpriteSet *CtrlSet::getSprites(){
    if (ss != 0) return ss;
    
//     DBGWARN
    pr("\n\nconstructMesh\n");
    
    static bool mwCalc;
    if (!mwCalc) {
        calcMeshWeights();
        mwCalc = true;
    }

    
    // Determine the offsets of these control points from the base values

    FlPoint2 po[CPTS];
    
    for (int j = 0; j < CPTS; j++) {
        FlPoint2 &cpt = pt(j);
        FlPoint2 &bpt = baseSet().pt(j);
        po[j].setTo(cpt.x - bpt.x, cpt.y - bpt.y);
        
        pr(" offset %d = %s\n",j,d(po[j]));
    }
    
    FlPoint2 m[MESH_PTS];
    
    for (int y = 0; y < MESH_Y; y++) {
        for (int x = 0; x < MESH_X; x++) {
            int i = y*MESH_X + x;
            
            float px = x / (float)(MESH_X-1);
            float py = y / (float)(MESH_Y-1);
            
            // Start with the base set's point,
            // then perturb it by the weighted perturbations of the control points
            
            for (int j = 0; j < CPTS; j++) {
                float wt = meshWeights[(i*CPTS + j)];
                px += po[j].x * wt;
                py += po[j].y * wt;
            }
            m[i].setTo(px,py);
            pr(" set mesh point %d,%d to %s\n",x,y,d(m[i]));
        }
        pr("\n");
    }
    
    
    
    Vector<float> spi;
    
    for (int ty = 0; ty < MESH_Y-1; ty++) {
        for (int tx = 0; tx < MESH_X-1; tx++) {
            
            int mj = ty*MESH_X + tx;
            
 
            FlPoint2 *mpt;
            FlPoint2 *tc;
            mpt = &m[mj]; spi.push_back(mpt->x); spi.push_back(mpt->y);
            mpt = &m[mj+1]; spi.push_back(mpt->x); spi.push_back(mpt->y);
            mpt = & m[mj+MESH_X]; spi.push_back(mpt->x); spi.push_back(mpt->y);
            tc = &texCoords[mj]; spi.push_back(tc->x);spi.push_back(tc->y);
            tc = &texCoords[mj+1]; spi.push_back(tc->x);spi.push_back(tc->y);
            tc = &texCoords[mj+MESH_X]; spi.push_back(tc->x);spi.push_back(tc->y);
            
            if (!showMeshMode) {
#if !SHOW_MESH
            mpt = &m[mj+1]; spi.push_back(mpt->x); spi.push_back(mpt->y);
            mpt = &m[mj+MESH_X]; spi.push_back(mpt->x); spi.push_back(mpt->y);
            mpt = &m[mj+MESH_X+1]; spi.push_back(mpt->x); spi.push_back(mpt->y);
            tc = &texCoords[mj+1]; spi.push_back(tc->x);spi.push_back(tc->y);
            tc = &texCoords[mj+MESH_X]; spi.push_back(tc->x);spi.push_back(tc->y);
            tc = &texCoords[mj+MESH_X+1]; spi.push_back(tc->x);spi.push_back(tc->y);
#endif
            }
            
        }
    }
    
    
    
    newobj(ss, CompiledSpriteSet(spi,0,spi.size()/12));
    
    return ss;
}


/**
 Construct a random set of offsets for variable control points
 */
void rndCtrlPerturb(PtsVec &v) {
    
    
#define  A (1 / 3.0f)
#define  B (1 - A)
#define C (A*.3)
    
#define ENDMARKER -999
    static float ss[] = {
        A-C,A+C,B-C,A+C,B-C,B+C,A-C,B+C, //
        A-C,A-C,B-C,A-C,B-C,B-C,A-C,B-C, //
        A+C,A-C,B+C,A-C,B+C,B-C,A+C,B-C, //
        A+C,A+C,B+C,A+C,B+C,B+C,A+C,B+C, //
        
        A*.6,A,B*.6,A,B*.6,B,A*.6,B,
        1-B*.6,A,1-A*.6,A, 1-A*.6,B,1-B*.6,B,
         
        A,1-B*.6,B,1-B*.6,B,1-A*.6,A,1-A*.6, //
       A,A*.6,B,A*.6,B,B*.6,A,B*.6, //
        
        .5,.5,.5,.5,.5,.5,.5,.5, //
        0,.5,A,.5,B,.5,1,.5, //
        .5,0,.5,A,.5,B,.5,1, //
        0,0,1,0,1,1,0,1, //
        0,0,A,A,B,B,1,1, //
        1,0,B,A,A,B,0,1, //
        B,A,B,B,A,B,A,A, //
        B,B,A,B,A,A,B,A, //
        
#undef C
#define C -.03
        A-C,A-C,B+C,A-C,B+C,B+C,A-C,B+C,
#undef C
#define C .03
        A-C,A-C,B+C,A-C,B+C,B+C,A-C,B+C,
        
        A,A-C,B,A+C,B,B-C,A,B+C,
        A,A+C,B,A-C,B,B+C,A,B-C,
        A-C,A,B+C,A,B-C,B,A+C,B,
        A+C,A,B-C,A,B+C,B,A-C,B,
        
        ENDMARKER
    };
#undef A
#undef B
#undef C
    
    // DBGWARN
    
    pr("\nrndCtrlPerturb\n");
    
    CtrlSet &base = CtrlSet::baseSet();
    v.clear();
    
#define TEST 0
    
    if (TEST || rand() % 100 > 30) {
        pr(" choosing preset...\n");
        static int nPresets;
        if (!nPresets) {
            while (ss[nPresets * CPTS * 2] != ENDMARKER)
                nPresets++;
        }
        int s = (rand() % nPresets)*CPTS*2;
        if (TEST)
            s = 0;
        
        for (int i =0 ; i < CPTS; i++,s+=2) {
            FlPoint2 p(ss[s],ss[s+1]);
            v.push_back(p);
        }
        
    } else {
        pr(" choosing rnd...\n");
        for (int i =0 ; i < CPTS; i++) {
            FlPoint2 p;
            FlPoint2 &bp = base.pt(i);
            p.x = rndf(STRETCHY) + bp.x;
            p.y = rndf(STRETCHY) + bp.y;
            v.push_back(p);
        }
    }
    
}

/**
 Negate coordinates of a set of control points
 */
void pertNeg(PtsVec &v) {
    CtrlSet &base = CtrlSet::baseSet();
    for (int i = 0; i < v.size(); i++) {
        FlPoint2 &n = base.pt(i);
        v[i].x = 2*n.x - v[i].x;
        v[i].y = 2*n.y - v[i].y;
    }
}

/**
 Apply a scaling factor to a set of control points
 */
void pertScale(Vector<FlPoint2> &vOrig, float scale, Vector<FlPoint2> &dest) {
    dest.clear();
    for (int i = 0; i < vOrig.size(); i++) {  
        FlPoint2 &src = vOrig[i];
        FlPoint2 pt(src.x * scale, src.y * scale);
        dest.push_back(pt);
    }
}

/**
 Construct a CtrlSet from a set of variable control points
 */
CtrlSet *csetFrom(Vector<FlPoint2> &pert) {
    // DBGWARN
    CtrlSet *cs = new CtrlSet();
    for (int i =0 ; i < pert.size(); i++) {
        cs->pt(i) = pert[i];
        pr("pert #%d = %s\n",i,d(pert[i]));
    }
    return cs;
}

/**
 Build the default set of variable control points (the points in their unperturbed positions)
 */
void buildBasePoints(Vector<FlPoint2> &dest) {
    for (int i =0 ; i < CPTS; i++) {
        dest.push_back(CtrlSet::baseSet().pt(i));
    }
}

void clearCtrlSetVector(Vector<CtrlSet *> &csets) {
    while (!csets.empty()) {
        CtrlSet *s = csets.back();
        delete s;
        csets.pop_back();
    }
}

/**
 Build a set of CtrlSets to transition from a start to final variable control points configuration
 */
void buildCtrlSets(Vector<FlPoint2> &orig, Vector<FlPoint2> &dest, int nFrames, Vector<CtrlSet *> &csets) {
  
//    DBGWARN
    clearCtrlSetVector(csets);
    for (int i = 0; i < nFrames; i++) {
        float s = i / (float)(nFrames-1);
        
        Vector<FlPoint2> ptb;
        for (int j = 0; j < orig.size(); j++) {
            FlPoint2 &p0 = orig[j];
            FlPoint2 &p1 = dest[j];
            FlPoint2 p2(p0.x + (p1.x - p0.x) * s,
                        p0.y + (p1.y - p0.y) * s);
            ptb.push_back(p2);
            
            pr(" %s ... %s  by %s = %s\n",d(p0),d(p1),d(s),d(p2));
        }
        CtrlSet *cs = csetFrom(ptb);
        // pre-build the sprites, before animation takes place
        cs->getSprites();
        
        csets.push_back(cs);
    }
}


