#pragma once
#include <cmath>
#include "Base.h"

// ----------------------------------------------------
// Constants
// ----------------------------------------------------

#define PI 3.141592654f
#define DEGTORAD (PI / 180)

// ----------------------------------------------------
// Utility functions
// ----------------------------------------------------

int mod(int value, int divisor);
float modf(float value, float divisor);
float min(float a, float b);
int min(int a, int b);
int max(int a, int b);
int ceil(int position, int gridSize);
int floor(int position, int gridSize);

float max(float a, float b);
void clamp(int &val, int min, int max);
void clamp(float &val, float min, float max);
int round(float a);

#if DEBUG
#define NOTNAN(x)  ASSERT((x) == (x))
#else
#define NOTNAN(x)
#endif

/**
 * Snap a scalar to a grid
 * @param n scalaar
 * @param size size of grid cells (assumed to be square)
 * @return point snapped to nearest cell corner (or to bottom left, if round false)
 */
void snapToGrid(float &n, float size, bool round = true);
void snapToGrid(int &n, int size, bool round = true);

/**
 * Normalize an angle by replacing it, if necessary, with an
 * equivalent angle in the range [-PI,PI)
 *
 * @param a  angle to normalize
 * @return an equivalent angle in [-PI,PI)
 */
float angle(float a);

/**
 * Normalize an angle by replacing it, if necessary, with an
 * equivalent angle in the range [0,2*PI)
 *
 * @param a  angle to normalize
 * @return an equivalent angle in [0,2*PI)
 */
float angle2(float a);

inline int sign(float f) {
	return (f < 0) ? -1 : ((f > 0) ? 1 : 0);
    
}
// ----------------------------------------------------
// Classes
// ----------------------------------------------------

// Declare classes ahead of time, since some will supply conversions

class IPoint2;
class FlPoint2;
class FlPoint3;
class FlPoint4;
class IRect;
class FlRect;
class FlMatrix;

class FlPoint2 {
public:
	float x, y;
    
	FlPoint2(IPoint2 ipt);
	FlPoint2() {
		x = 0;
		y = 0;
	}
	FlPoint2(float x, float y) {
		this->x = x;
		this->y = y;
	}
	FlPoint2 & operator=(const IPoint2 &src);
    
	bool equals(FlPoint2 &r) const {
		return r.x == x && r.y == y;
	}
    
	void clear() {
		setTo(0, 0);
	}
    
	void negate() {
		x = -x;
		y = -y;
	}
    
	void scale(float s) {
		x *= s;
		y *= s;
	}
    
	void translate(float x, float y, bool neg = false) {
		if (neg) {
			x = -x;
			y = -y;
		}
		this->x += x;
		this->y += y;
	}
    
	void translate(FlPoint2 &amt, bool neg = false) {
		translate(amt.x, amt.y, neg);
	}
    
	void setTo(float x, float y) {
		this->x = x;
		this->y = y;
	}
	void setTo(const FlPoint2 &pt) {
		setTo(pt.x, pt.y);
	}
    
	float lengthSq() const {
		return x * x + y * y;
	}
    
	float length() const {
		return sqrt(lengthSq());
	}
	bool equals(FlPoint2 &c) {
		return x == c.x && y == c.y;
	}
    
	float normalize();
	void exchange() {
		float tmp = x;
		x = y;
		y = tmp;
	}
	/**
	 * Compare two points lexicographically
	 * > a, b points
	 * < sign of (a - b), where compared by y-coordinates, then by x-coordinates to break ties
	 */
	static int compare(const FlPoint2 &a, const FlPoint2 &b) {
		float res = a.y - b.y;
		if (!res)
			res = a.x - b.x;
		return sign(res);
	}
#if DEBUG
	String toString();
#endif
    
};

extern FlPoint2 zero2;

void add(const FlPoint2 & a, const FlPoint2 & b, FlPoint2 &d);
void difference(const FlPoint2 &b, const FlPoint2 &a, FlPoint2 &d);
inline FlPoint2 difference(const FlPoint2 &b, const FlPoint2 &a) {
	return FlPoint2(b.x - a.x, b.y - a.y);
}
void addMultiple(const FlPoint2 &a, float mult, const FlPoint2 &b,
                 FlPoint2 &dest);
void interpolate(const FlPoint2 & p1, const FlPoint2 &p2, float t, FlPoint2 &d);

/**
 * Convert an interpolant factor [0..1] to a smooth curve that
 * accelerates and deaccelerates at end
 * @param factor interpolant; clamped to [0...1]
 * @param smooth factor [0..1]
 */
float smoothInterpolant(float factor);
void midPoint(const FlPoint2 &p1, const FlPoint2 &p2, FlPoint2 &d);
float distance(const FlPoint2 &a, const FlPoint2 &b);
float distanceSq(float ax, float ay, float bx, float by);
float distance(float ax, float ay, float bx, float by);
float distanceSq(const FlPoint2 &a, const FlPoint2 &b);
void ptOnCircle(const FlPoint2 &origin, float angle, float radius,
                FlPoint2 &dest);
#if DEBUG
FlPoint2 ptOnCircle(const FlPoint2 &origin, float angle, float radius
                    );
#endif

bool lineLineIntersection(const FlPoint2 &m1, const FlPoint2 &m2,
                          const FlPoint2 &q1, const FlPoint2 &q2, FlPoint2 &dest, float *param =
                          NULL);

inline float polarAngle(float dy, float dx) {
	return atan2f(dy, dx);
}
float polarAngle2(float dy, float dx);

inline float polarAngle(const FlPoint2 &s0, const FlPoint2 &s1) {
	return polarAngle(s1.y - s0.y, s1.x - s0.x);
}

inline float polarAngle2(const FlPoint2 &s0, const FlPoint2 &s1) {
	return polarAngle2(s1.y - s0.y, s1.x - s0.x);
}

/**
 * Determine which side of a line a point is on; floating point version
 * @param ax
 * @param ay first point on line
 * @param bx
 * @param by second point on line
 * @param px
 * @param py point to test
 * @return 0 if the point is on the line containing the ray from a to b,
 *  positive value if it's to the left of this ray, negative if it's to the right
 */
float sideOfLine(const FlPoint2 &s1, const FlPoint2 &s2, const FlPoint2 &pt);

int sideOfLine(const IPoint2 &s1, const IPoint2 &s2, const IPoint2 &pt);

class IPoint2 {
public:
	int x, y;
	IPoint2(int x = 0, int y = 0) {
		this->x = x;
		this->y = y;
	}
	IPoint2(const FlPoint2 &fpt) {
		setTo(fpt.x, fpt.y);
	}
	IPoint2(float x, float y) {
		setTo(x, y);
	}
	int comp(int index) const {
		ASSERT(index >= 0 && index < 2);
		return (&x)[index];
	}
	void clear() {
		x = 0;
		y = 0;
	}
	void setComp(int index, int val) {
		ASSERT(index >= 0 && index < 2);
		(&x)[index] = val;
	}
	void addToComp(int index, int val) {
		ASSERT(index >= 0 && index < 2);
		(&x)[index] += val;
	}
	bool equals(const IPoint2 &a) const {
		return a.x == x && a.y == y;
	}
	void exchange() {
		int tmp = x;
		x = y;
		y = tmp;
	}
	void translate(int x, int y, bool neg = false) {
		if (neg) {
			x = -x;
			y = -y;
		}
		this->x += x;
		this->y += y;
	}
	void translate(IPoint2 amt, bool neg = false) {
		translate(amt.x, amt.y, neg);
	}
	void add(IPoint2 amt) {
		translate(amt);
	}
	void add(int x, int y) {
		translate(x, y);
	}
    
	void scale(float f) {
		x = round(x * f);
		y = round(y * f);
	}
    
	void setTo(int x, int y) {
		this->x = x;
		this->y = y;
	}
    
	void setTo(float fx, float fy) {
		//DBGWARN
		setTo(round(fx), round(fy));
		pr(
           "setTo (float) %f, %f,  round yields %d, %d and result %s\n", fx, fy, round(fx), round(fy), d(this));
	}
    
	void setTo(const IPoint2 &t) {
		setTo(t.x, t.y);
	}
    
	/**
	 * Compare two points lexicographically
	 * > a, b points
	 * < sign of (a - b), where compared by y-coordinates, then by x-coordinates to break ties
	 */
	static int compare(const IPoint2 &a, const IPoint2 &b) {
		int res = a.y - b.y;
		if (!res)
			res = a.x - b.x;
		return res;
	}
    
	bool degenerate() {
		return x <= 0 || y <= 0;
	}
    
#if DEBUG
	String toString() const;
#endif
};

void add(const IPoint2 &a, const IPoint2 &b, IPoint2 &d);
float distance(const IPoint2 &a, const IPoint2 &b);
int distanceSq(int ax, int ay, int bx, int by);
float distance(int ax, int ay, int bx, int by);
float distanceSq(const IPoint2 &a, const IPoint2 &b);
void difference(const IPoint2 &b, const IPoint2 &a, IPoint2 &d);

class FlPoint3 {
public:
	float x, y, z;
    
	FlPoint3(float x = 0, float y = 0, float z = 0) {
		setTo(x, y, z);
	}
    
	void setTo(float x, float y, float z) {
		this->x = x;
		this->y = y;
		this->z = z;
	}
    
	void setTo(const FlPoint3 &v) {
		setTo(v.x, v.y, v.z);
	}
    
	void add(float x, float y, float z) {
		this->x += x;
		this->y += y;
		this->z += z;
	}
    
	void add(const FlPoint3 &pt) {
		add(pt.x, pt.y, pt.z);
	}
    
	/**
	 * Get the square of the distance of this point from the origin
	 * @return square of distance from origin
	 */
	float lengthSq() const {
		return x * x + y * y + z * z;
	}
    
	/**
	 * Get the distance of this point from the origin
	 * @return distance from origin
	 */
	float length() const {
		return sqrt(lengthSq());
	}
    
	/**
	 * Adjust location of point so it lies at unit distance, in
	 * the same direction from the origin as the original.  If point is at origin,
	 * leaves it there.
	 * return the original point's distance from the origin, squared
	 */
	float normalize();
    
	void negate() {
		x = -x;
		y = -y;
		z = -z;
	}
    
	void scale(float d) {
		x *= d;
		y *= d;
		z *= d;
	}
#if DEBUG
	String toString();
#endif
    
};

/**
 * Interpolate between two points
 * @param a : first point
 * @param b : second point
 * @param mult : interpolation factor (0=a, 1=b)
 * @param dest : where to store interpolated point, or null to construct
 * @return interpolated point
 */
void interpolate(const FlPoint3 & a, const FlPoint3 & b, float mult,
                 FlPoint3 &dest);
void add(const FlPoint3 &a, const FlPoint3 &b, FlPoint3 &dest);
void addMultiple(const FlPoint3 &a, float mult, const FlPoint3 &b,
                 FlPoint3 &dest);
float distance(const FlPoint3 & a, const FlPoint3 & b);
float distanceSq(const FlPoint3 & a, const FlPoint3 & b);
/**
 * Returns the square of the distance between two 3d points
 * @param x1
 * @param y1
 * @param z1 first point
 * @param x2
 * @param y2
 * @param z2 second point
 * @return the square of the distance between the two points
 */
float distanceSq(float x1, float y1, float z1, float x2, float y2, float z2);
/**
 * Returns the distance between two 3d points
 * @param x1
 * @param y1
 * @param z1 first point
 * @param x2
 * @param y2
 * @param z2 second point
 * @return the distance between the two points
 */
float distance(float x1, float y1, float z1, float x2, float y2, float z2);
void difference(const FlPoint3 & b, const FlPoint3 & a, FlPoint3 &d);
void crossProduct(const FlPoint3 & a, const FlPoint3 & b, const FlPoint3 & c,
                  FlPoint3 &dest);
/**
 * Calculate the inner (dot) product of two points
 * @param s
 * @param t
 * @return the inner product
 */
float innerProduct(const FlPoint3 & s, const FlPoint3 & t);

void crossProduct(float x1, float y1, float z1, float x2, float y2, float z2,
                  FlPoint3 &dest);
void crossProduct(const FlPoint3 & a, const FlPoint3 & b, FlPoint3 &dest);
float innerProduct(float x1, float y1, float z1, float x2, float y2, float z2);

class IRect {
public:
	int x, y, width, height;
	void inset(int amt) {
		x += amt;
		y += amt;
		width -= amt * 2;
		height -= amt * 2;
	}
	IRect(int x = 0, int y = 0, int w = 0, int h = 0) {
		this->x = x;
		this->y = y;
		this->width = w;
		this->height = h;
	}
	bool equals(const IRect &r) const {
		return r.x == x && r.y == y && r.width == width && r.height == height;
	}
    
	IPoint2 &position() {
		return *(IPoint2 *) &x;
	}
	IPoint2 &size() {
		return *(IPoint2 *) &width;
	}
    
	void translate(int x, int y) {
		this->x += x;
		this->y += y;
	}
	void translate(IPoint2 pt) {
		translate(pt.x, pt.y);
	}
	IRect(const FlRect *r);
	IRect(const IRect &r) {
		setTo(r.x, r.y, r.width, r.height);
	}
	void setTo(int x, int y, int w, int h) {
		this->x = x;
		this->y = y;
		this->width = w;
		this->height = h;
	}
	void setTo(float x, float y, float w, float h) {
		setTo(round(x), round(y), round(w), round(h));
	}
	void setSize(const IPoint2 &size) {
		setSize(size.x, size.y);
	}
	IPoint2 minPt() {
		return IPoint2(x, y);
	}
	IPoint2 maxPt() {
		return IPoint2(endX(), endY());
	}
	void setSize(int w, int h) {
		this->width = w;
		this->height = h;
	}
	void setPosition(int x, int y) {
		this->x = x;
		this->y = y;
	}
	void setPosition(const IPoint2 &pos) {
		setPosition(pos.x, pos.y);
	}
    
	IRect(const IPoint2 &p0, const IPoint2 &p1) {
		x = min(p0.x, p1.x);
		y = min(p0.y, p1.y);
		width = max(p0.x, p1.x) - x;
		height = max(p0.y, p1.y) - y;
	}
    
	int endX() const {
		return x + width;
	}
	int endY() const {
		return y + height;
	}
	bool intersects(const IRect &s) const {
		return x < s.endX() && s.x < endX() && y < s.endY() && s.y < endY();
	}
	bool degenerate() {
		return width <= 0 || height <= 0;
	}
	void add(int px, int py);
	void add(const IRect &r) {
		add(r.x, r.y);
		add(r.endX(), r.endY());
	}
    
	//  IPoint2 size() const {return IPoint2(width,height);}
	void add(const IPoint2 &pt) {
		add(pt.x, pt.y);
	}
    
	bool contains(const IRect &r) const {
		return x <= r.x && y <= r.y && endX() >= r.endX() && endY() >= r.endY();
	}
    
	bool contains(const IPoint2 &pt) const {
		return pt.x <= endX() && pt.y <= endY() && pt.x >= x && pt.y >= y;
	}
    
	int midX() const {
		return x + width / 2;
	}
    
	int midY() const {
		return y + height / 2;
	}
    
	IPoint2 midPoint() {
		return IPoint2(midX(), midY());
	}
    
	void scale(float f) {
		x = round(f * x);
		y = round(f * y);
		width = round(f * width);
		height = round(f * height);
	}
    
	void setTo(const IRect &r) {
		setTo(r.x, r.y, r.width, r.height);
	}
    
	int &posComp(int index) {
		ASSERT(index >= 0 && index < 2);
		return (&x)[index];
	}
	int &sizeComp(int index) {
		ASSERT(index >= 0 && index < 2);
		return (&width)[index];
	}
    
#if DEBUG
	String toString();
#endif
};

/**
 Calculate intersection of rectangles a and b.
 If intersection is empty, destination is undefined and returns false.
 */
bool intersect(IRect &a, IRect &b, IRect &dest);

class FlRect {
public:
	float x, y, width, height;
	float area() {
		return width * height;
	}
	FlRect(const IRect &ir) {
		this->x = ir.x;
		this->y = ir.y;
		this->width = ir.width;
		this->height = ir.height;
	}
    
	FlPoint2 &size() {
		return *(FlPoint2 *) &width;
	}
    
	float midX() const {
		return (x + width * .5f);
	}
	float midY() const {
		return (y + height * .5f);
	}
    
	bool equals(const FlRect &r) const {
		return r.x == x && r.y == y && r.width == width && r.height == height;
	}
    
	FlRect(float x = 0, float y = 0, float w = 0, float h = 0) {
		this->x = x;
		this->y = y;
		this->width = w;
		this->height = h;
	}
	void setTo(float x, float y, float w, float h) {
		this->x = x;
		this->y = y;
		this->width = w;
		this->height = h;
	}
	void add(const FlPoint2 &pt) {
		add(pt.x, pt.y);
	}
	void add(float x, float y);
	void add(const FlRect &r) {
		add(r.x, r.y);
		add(r.endX(), r.endY());
	}
	void setTo(const FlRect &r) {
		setTo(r.x, r.y, r.width, r.height);
	}
	/**
	 * Construct smallest rectangle containing two points
	 * @param pt1
	 * @param pt2
	 */
	FlRect(const FlPoint2 &pt1, const FlPoint2 &pt2) {
		x = min(pt1.x, pt2.x);
		y = min(pt1.y, pt2.y);
		width = max(pt1.x, pt2.x) - x;
		height = max(pt1.y, pt2.y) - y;
	}
	FlPoint2 bottomRight() const {
		FlPoint2 pt(endX(), y);
		return pt;
	}
	FlPoint2 topLeft() const {
		FlPoint2 pt(x, endY());
		return pt;
	}
    
	FlPoint2 bottomLeft() const {
		FlPoint2 pt(x, y);
		return pt;
	}
    
	FlPoint2 topRight() const {
		FlPoint2 pt(endX(), endY());
		return pt;
	}
    
	float endX() const {
		return x + width;
	}
    
	float endY() const {
		return y + height;
	}
    
	bool contains(const FlRect &r) const {
		return x <= r.x && y <= r.y && endX() >= r.endX() && endY() >= r.endY();
	}
    
	void translate(float dx, float dy) {
		x += dx;
		y += dy;
	}
    
	FlPoint2 midPoint() const {
		FlPoint2 pt(midX(), midY());
		return pt;
	}
	bool contains(const FlPoint2 &pt) const {
		return x <= pt.x && y <= pt.y && endX() >= pt.x && endY() >= pt.y;
	}
    
	void translate(const FlPoint2 &tr) {
		translate(tr.x, tr.y);
	}
    
	void scale(float f) {
		x *= f;
		y *= f;
		width *= f;
		height *= f;
	}
#if DEBUG
	String toString();
#endif
    
};

class FlPoint4 {
public:
	float x, y, z, w;
	FlPoint4(float x = 0, float y = 0, float z = 0, float w = 1) {
		this->x = x;
		this->y = y;
		this->z = z;
		this->w = w;
	}
#if DEBUG
	String toString();
#endif
};

// --------------------------------------------------------------------
// MARK: -
// MARK: FlMatrix
// --------------------------------------------------------------------

// Like OpenGL, our matrix is in column-major format.
// Cell row(0..h-1), col(0..w-1) has index (col * h + row).

class FlMatrix {
public:
	float *c;
	short w, h;
	FlMatrix(int height, int width);
	~FlMatrix();
    
	const float *coeff() const {
		return const_cast<float *>(c);
	}
    
	/**
	 * Get coefficient from matrix, by returning coeff[y*width + x].
	 * @param y : row (0..height-1)
	 * @param x : column (0..width-1)
	 * @return coefficient
	 */
	float get(int row, int col) const;
    
	// Reset to identity matrix
	void setToIdentity();
    
	/**
	 * Invert matrix
	 * @param d destination matrix (if null, creates it; can be same as source)
	 * @return destination matrix
	 */
	void invert(FlMatrix &dest) const;
    
	/**
	 * Multiply two matrices.  Destination can be same as one of the two.
	 * @param a first matrix
	 * @param b second matrix
	 * @param d destination matrix
	 * @return destination matrix
	 */
	static void multiply(const FlMatrix &a, const FlMatrix &b, FlMatrix &d);
    
	// --------------------------------------------------------------------
	// MARK: -
	// MARK: Uncategorized...
	// --------------------------------------------------------------------
    
	void set(int row, int col, float f);
    
	void setTo(const FlMatrix &src);
    
	void scale(float s, FlMatrix &dest) const;
    
#if DEBUG
	String toString();
#endif
    
	// --------------------------------------------------------------------
	// MARK: -
	// MARK: 2D Operations
	// --------------------------------------------------------------------
    
	/**
	 * Transform 2D point through 3x3 homogeneous matrix
	 * > x,y
	 * < result
	 */
	void apply(float x, float y, FlPoint2 &result) const;
    
	/**
	 * Transform 2D point through 3x3 homogeneous matrix
	 * > pt
	 * < result (can be same as pt)
	 */
	void apply(const FlPoint2 &pt, FlPoint2 &result) const {
		apply(pt.x, pt.y, result);
	}
    
	/**
	 Set to 2D translation matrix
	 > tx, ty
	 */
	void setToTranslate(float tx, float ty);
	void setToTranslate(FlPoint2 &pt) {
		setToTranslate(pt.x, pt.y);
	}
	void setToScale(float x, float y);
	void setToScale(FlPoint2 &pt) {
		setToScale(pt.x, pt.y);
	}
    
	// --------------------------------------------------------------------
	// MARK: -
	// MARK: 3D Operations
	// --------------------------------------------------------------------
    
	/**
	 * Transform 3D point through 4x4 homogeneous matrix
	 * > pt
	 * < result (can be same as pt)
	 */
	void apply(const FlPoint4 &pt, FlPoint4 &result) const;
	void getRotate(float r);
    
	void getTranslate(const FlPoint3 &pt, bool neg = false);
	void setToScale(float x, float y, float z);
	/*
	 * Set matrix to 3d scale matrix
	 */
	void setToScale(const FlPoint3 &pt) {
		setToScale(pt.x, pt.y, pt.z);
	}
	/*
	 * Get 3d translation matrix
	 */
	void setToTranslate(float x, float y, float z);
    
	/*
	 * Set x translation for 3x3 matrix
	 */
	void setTranslateX(float tx) {
		ASSERT(w == 3 && h == 3);
		c[2 * 3 + 0] = tx;
	}
	/*
	 * Set y translation for 3x3 matrix
	 */
	void setTranslateY(float ty) {
		ASSERT(w == 3 && h == 3);
		c[2 * 3 + 1] = ty;
	}
    
	/*
	 * Get 3d translation matrix
	 */
	void setToTranslate(const FlPoint3 &pt) {
		setToTranslate(pt.x, pt.y, pt.z);
	}
	/*
	 * Initialize 4x4 matrix to coefficients
	 * > coeff coefficients given as four rows (i.e.,
	 *  in human readable orientation)
	 */
	void set44(const float *coeff);
    
	// --------------------------------------------------------------------
	// MARK: -
	// MARK: Private members
	// --------------------------------------------------------------------
    
private:
	// make these private to prevent use
	FlMatrix(const FlMatrix &src) {
		ASSERT(false);
	}
	FlMatrix & operator=(const FlMatrix &src) {
		ASSERT(false);
		return *this;
	}
};

#if DEBUG
inline String d(int x, int y) {IPoint2 t(x,y); return d(t);}
inline String d(float x, float y) {FlPoint2 t(x,y); return d(t);}
const char *dh(FlPoint2 pt);
#endif

class Random {
public:
	enum {
		MAX = 0x7fffffff,
	};
    
	/*
	 * Constructor
	 * > seed
	 */
	Random(uint seed = 1965);
    
	/*
	 * Calculate random number from 0..maxVal-1
	 * > maxVal
	 */
	int rnd(uint maxVal);
    
	/*
	 * Calculate random number from 0..0x7fffffff
	 */
	int rnd();
	/*
	 * Calculate random boolean value
	 */
	bool rndBool();
    
	/*
	 * Get random float from [0...1)
	 */
	float randf();
    
	/*
	 * Get random float from [0...range)
	 */
	float randf(float range);
    
	/*
	 * Get a random number [0..1), weighted towards 0
	 */
	float weighted();
    
	/*
	 * Get random number from [-range/2 .. range)
	 */
	float randfs(float range);
    
private:
	uint mw_, mz_;
};

float signedPtDistanceToLine(FlPoint2 &pt, FlPoint2 &e0, FlPoint2 &e1);
/**
 * Determine distance of a point from a line
 * @param pt FPoint2
 * @param e0   one point on line
 * @param e1   second point on line
 * @param closestPt if not null, closest point on line is stored here
 * @return distance
 */
inline float ptDistanceToLine(FlPoint2 &pt, FlPoint2 &e0, FlPoint2 &e1) {
	return fabs(signedPtDistanceToLine(pt, e0, e1));
}

/**
 * Calculate the parameter for a point on a line
 * @param pt FPoint2, assumed to be on line
 * @param s0 start point of line segment (t = 0.0)
 * @param s1 end point of line segment (t = 1.0)
 * @return t value associated with pt
 */
float positionOnSegment(FlPoint2 &pt, FlPoint2 &s0, FlPoint2 &s1);

/**
 * Determine distance of point pt from segment l0...l1
 * < t if not null, parameter along segment returned here
 */
float ptDistanceToSegment(FlPoint2 &pt, FlPoint2 &l0, FlPoint2 &l1,
                          float *t = 0);

float rndf(float range, bool center = true);
