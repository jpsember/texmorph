#import "Sprite.h"

// Structure of noncompiled triangle (each field is a float):
enum {
	U_VERTICES,
	U_VERTICES_LAST = U_VERTICES + 3 * 2 - 1,
	U_TEXCOORDS,
	U_TEXCOORDS_LAST = U_TEXCOORDS + 3 * 2 - 1,
	U_TOTAL,
};

bool showMeshMode;

/*
 * Structure of compiled vertices; these are stored
 * in the Vertex Buffer Objects.
 */
typedef struct {
	float location[2];
	float tex[2];
} CompiledVertex;


CompiledSpriteSet::~CompiledSpriteSet() {
	deleteBuffer(vbo_);
	deleteBuffer(ibo_);
}

void CompiledSpriteSet::render(int texId) {
#undef p2
#define p2(a)  //pr(a)
	p2(("CompiledSpriteSet.render(), %d vertices, texture=%d vbo=%d\n",textureId_,vbVertices_,vbo_ ));
    
	setRenderState( RENDER_SPRITE);
    
	p2((" selecting texture %d\n",textureId_ ));
    
    
    
    selectTexture(texId);
    
	// Bind our buffers much like we would for texturing
	glBindBuffer(GL_ARRAY_BUFFER, vbo_);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_);
    
	CompiledVertex *nullPtr = (CompiledVertex *) NULL;
	glTexCoordPointer(2, GL_FLOAT, sizeof(CompiledVertex), nullPtr->tex);
	glVertexPointer(2, GL_FLOAT, sizeof(CompiledVertex), nullPtr->location);
    
    
	// Actually do our drawing
	glDrawElements(GL_TRIANGLES, vbVertices_,
                   GL_UNSIGNED_SHORT, 0);
    
}

CompiledSpriteSet::CompiledSpriteSet(Vector<float> &tData, int offset,
                                     int nTriangles) {
    //DBWARN
	pr("CompiledSpriteSet constructor, nTriangles=%d\n",nTriangles);
    
    
#undef RI
#undef RF
#define RI(ind) (tData[offset+ind])
#define RF(ind) (tData[offset+ind])
    
	int nVerts = nTriangles * 3;
    
	glGenBuffers(1, &vbo_); // Create the buffer ID, this is basically the same as generating texture ID's
    ADJALLOC("glbuffer", 1);
    
	glBindBuffer(GL_ARRAY_BUFFER, vbo_); // Bind the buffer (vertex array data)
    
	pr(" vbo_ allocated=%u\n",vbo_);
    
	{
		// Allocate space.  We could pass the mesh in here (where the NULL is), but it's actually faster to do it as a
		// seperate step.  We also define it as GL_STATIC_DRAW which means we set the data once, and never
		// update it.  This is not a strict rule code wise, but gives hints to the driver as to where to store the data
		int vbuffLength = sizeof(CompiledVertex) * nVerts;
        
        void *vbuff = malloc(vbuffLength);
        ADJALLOC("malloc", 1);
        
        CompiledVertex *dest = (CompiledVertex *) vbuff;
        
        
		for (int q = 0; q < nTriangles; q++, offset += U_TOTAL) {
            
			dest->location[0] = RF(U_VERTICES+0);
			dest->location[1] = RF(U_VERTICES+1);
			dest->tex[0] = RF(U_TEXCOORDS + 0);
			dest->tex[1] = RF(U_TEXCOORDS + 1);
			dest++;
            
			dest->location[0] = RF(U_VERTICES + 2);
			dest->location[1] = RF(U_VERTICES + 3);
			dest->tex[0] = RF(U_TEXCOORDS + 2);
			dest->tex[1] = RF(U_TEXCOORDS + 3);
			dest++;
            
			dest->location[0] = RF(U_VERTICES + 4);
			dest->location[1] = RF(U_VERTICES + 5);
			dest->tex[0] = RF(U_TEXCOORDS + 4);
			dest->tex[1] = RF(U_TEXCOORDS + 5);
			dest++;
            
		}
        
		p2((" upload data from %p\n",vbuff.buffer() ));
        
		glBufferData(GL_ARRAY_BUFFER, sizeof(CompiledVertex) * nVerts, NULL,
                     GL_STATIC_DRAW);
		glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(CompiledVertex) * nVerts,
                        vbuff);
        
        free(vbuff);
        ADJALLOC("malloc",-1);
        
	}
    
	// Set the pointers to our data.  Except for the normal value (which always has a size of 3), we must pass
	// the size of the individual component.  ie. A vertex has 3 points (x, y, z), texture coordinates have 2 (u, v) etc.
	// Basically the arguments are (ignore the first one for the normal pointer), Size (many components to
	// read), Type (what data type is it), Stride (how far to move forward - in bytes - per vertex) and Offset
	// (where in the buffer to start reading the data - in bytes)
    
	const CompiledVertex *nullPtr = (CompiledVertex *) NULL;
    
	// Make sure you put glVertexPointer at the end as there is a lot of work that goes on behind the scenes
	// with it, and if it's set at the start, it has to do all that work for each gl*Pointer call, rather than once at
	// the end.
	glTexCoordPointer(2, GL_FLOAT, sizeof(CompiledVertex), nullPtr->tex);
	//glNormalPointer(GL_FLOAT, sizeof(Vertex), BUFFER_OFFSET(20));
	//glColorPointer(4, GL_FLOAT, sizeof(Vertex), BUFFER_OFFSET(32));
	glVertexPointer(2, GL_FLOAT, sizeof(CompiledVertex), nullPtr->location);
    
	// When we get here, all the vertex data is effectively on the card
    
	{
		// index buffer has three values per triangle, or six values per sprite
		// *3 = 3 verts per triangle   *2 = 2 triangles per sprite
        
		vbVertices_ = 3 * nTriangles;
        
		int bytesPerIndex  =  2;
        
		int indBuffLen = bytesPerIndex  * vbVertices_;
        
        byte *indBuff = (byte *)malloc(indBuffLen);
        ADJALLOC("malloc", 1);
        
        word *ib = (word *) indBuff;
        int j = 0;
        int k = 0;
        for (int i = 0; i < nTriangles; i++) {
            ib[j++] = k;
            ib[j++] = k + 1;
            ib[j++] = k + 2;
            k += 3;
        }
        
		glGenBuffers(1, &ibo_);  
        ADJALLOC("glbuffer", 1);
        
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo_);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, indBuffLen, indBuff, GL_STATIC_DRAW);
        
        free(indBuff);
        ADJALLOC("malloc", -1);
    }
}

