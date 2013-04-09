#import "MyOpenGLView.h"

extern bool showMeshMode;
/*
 * A maximal set of compiled sprites; each sprite in the set
 * lies in the same atlas.
 */
class CompiledSpriteSet {
public:
	/*
	 * Constructor
	 * > triangleData vector containing uncompiled triangles
	 * > offset index of first triangle to compile to this object
	 * > nTriangles number of triangles to store in this set
	 */
	CompiledSpriteSet(Vector<float> &triangleData, int offset,
                      int nTriangles);
	~CompiledSpriteSet();
	void render(int texId);
private:
	// vertex buffer object
	uint vbo_;
	// index buffer object
	uint ibo_;
	// number of vertices this chunk represents
	int vbVertices_;
};
