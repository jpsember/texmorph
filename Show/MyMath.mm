#include "Base.h"
#include "MyMath.h"

using namespace std;

int min(int a, int b) {
	return a < b ? a : b;
}
int max(int a, int b) {
	return a > b ? a : b;
}
float min(float a, float b) {
	return a < b ? a : b;
}
float max(float a, float b) {
	return a > b ? a : b;
}

int round(float a) {
	return floor(a + .5f);
    
}
float polarAngle2(float dy, float dx) {
	float a = polarAngle(dy, dx);
	if (a < 0)
		a += 2 * PI;
	return a;
}

float rndf(float range, bool center) {
    float f = (rand() % 1000) * (range / 1000.0f);
    if (center)
        f -= range/2;
    return f;
}


int mod(int value, int divisor) {
	ASSERT(divisor > 0);
	value = value % divisor;
	if (value < 0)
		value += divisor;
	return value;
    
}
float smoothInterpolant(float t) {
	// derived from 4th degree polynomial
	return -2 * t * (t * (t - 1.5f));
    
	// others worth trying, with f(.5) = 2/3, =
    
	// 8/3 * t^4 - 22/3 * t^3  + 17/3 * t^2
    
	//  Catmull-Rom spline: doesn't have zero derivatives at 0,1
	// return t * (t * (1.5f - t) + .5f);
    //
    //	clamp(factor, 0.0f, 1.0f);
    //	return .5 + sinf(factor * PI - PI / 2) * .5;
}

//float polarAngle(const FlPoint2 &s0, const FlPoint2 &s1) {
//	return atan2f(s1.y - s0.y, s1.x - s0.x);
//}
//float randf(float range) {
//	float v = rand() * (range / RAND_MAX);
//	return v;
//}
//float randfs(float range) {
//	return randf(range) - range * .5;
//}

//float normalize(float theta){
//	float a = normalize2(theta);
//	if (a >= PI)
//		 a -= 2*PI;
//	return a;
//}

float modf(float value, float divisor) {
    
	//warn("UNTESTED");
	ASSERT(divisor > 0);
	float unused;
    
	float frac = modf(value / divisor, &unused);
	//pr(("modf value=%f divisor=%f frac=%f\n",value,divisor,frac));
    
	if (value < 0)
		frac += 1;
	return frac * divisor;
}

void ptOnCircle(const FlPoint2 &origin, float angle, float radius,
                FlPoint2 &dest) {
	dest.setTo(origin.x + cosf(angle) * radius,
               origin.y + sinf(angle) * radius);
}
#if DEBUG
FlPoint2 ptOnCircle(const FlPoint2 &origin, float angle, float radius
                    ) {
	FlPoint2 dest;
	ptOnCircle(origin,angle,radius,dest);
	return dest;
}
#endif

int ceil(int position, int gridSize) {
	return position + mod(-position, gridSize);
}

int floor(int position, int gridSize) {
	return position - mod(position, gridSize);
}

void snapToGrid(float &n, float size, bool round) {
	float k = n / size;
	if (round)
		k = roundf(k);
	else
		k = floorf(k);
	n = size * k;
}
void snapToGrid(int &n, int size, bool round) {
	float nf = n;
	float sf = size;
	snapToGrid(nf, sf, round);
	n = nf;
}

void clamp(int &val, int min, int max) {
	if (val < min)
		val = min;
	else if (val > max)
		val = max;
}
void clamp(float &val, float min, float max) {
	if (val < min)
		val = min;
	else if (val > max)
		val = max;
}
#undef C
#define C FlPoint2
#if DEBUG
const char *dh(FlPoint2 pt) {
	char *s = debugStr();
	sprintf(s,"(%f,%f) ",pt.x,pt.y);
	return s;
}
#endif

C zero2;

C & C::operator=(const IPoint2 &src) {
	this->x = src.x;
	this->y = src.y;
	return *this;
}
C::C(IPoint2 ipt) {
	setTo(ipt.x, ipt.y);
}

float C::normalize() {
	float lenSq = lengthSq();
	if (lenSq != 0 && lenSq != 1) {
		lenSq = sqrt(lenSq);
		float scale = 1 / lenSq;
		x *= scale;
		y *= scale;
	}
	return lenSq;
}

float sideOfLine(const FlPoint2 &s1, const FlPoint2 &s2, const FlPoint2 &pt) {
	float area2 = ((s2.x - s1.x)) * (pt.y - s1.y)
    - ((pt.x - s1.x)) * (s2.y - s1.y);
    
#if EMULATOR && DEBUG && 0
    
	double area3 = ((s2.x - s1.x)) * (double)(pt.y - s1.y) - ((pt.x - s1.x)) * (double)(s2.y
                                                                                        - s1.y);
	double diff = fabs(area2-area3);
	if (diff > fabs(area3) * .08f) {
        
		printf("sideOfLine problem, input points:\n %s\n %s\n %s\n float calc=%f\ndouble calc=%f\n",dfull(s1),dfull(s2),dfull(pt),area2,area3);
		die("sideOfLine problem");
	}
    
#endif
	return area2;
}

int sideOfLine(const IPoint2 &s1, const IPoint2 &s2, const IPoint2 &pt) {
	float area2 = ((s2.x - s1.x) * (float) (pt.y - s1.y))
    - ((pt.x - s1.x) * (float) (s2.y - s1.y));
	int ret = 0;
	if (area2 < 0)
		ret = -1;
	else if (area2 > 0)
		ret = 1;
	return ret;
}

bool lineLineIntersection(const FlPoint2 &m1, const FlPoint2 &m2,
                          const FlPoint2 &q1, const FlPoint2 &q2, FlPoint2 &dest, float *param) {
    
#undef p2
#define p2(a) //pr(a)
	const float EPS = 1e-5f;
	bool ret = false;
    
	do {
		float denom = (q2.y - q1.y) * (m2.x - m1.x)
        - (q2.x - q1.x) * (m2.y - m1.y);
		float numer1 = (q2.x - q1.x) * (m1.y - q1.y)
        - (q2.y - q1.y) * (m1.x - q1.x);
        
		p2(("lineLineIntersection denom=%f numer1=%f\n",denom,numer1));
		if (fabs(denom) < EPS)
			break;
        
		float ua = numer1 / denom;
        
		float numer2 = (m2.x - m1.x) * (m1.y - q1.y)
        - (m2.y - m1.y) * (m1.x - q1.x);
        
		float ub = numer2 / denom;
        
		if (param != null) {
			param[0] = ua;
			param[1] = ub;
		}
        
		//		p2((" ua=%f ulineLineIntersection denom=%f numer1=%f\n",denom,numer1));
		//
		//		if (ua < -EPS || ua > 1 + EPS) {
		//			break;
		//		}
		//		if (ub < -EPS || ub > 1 + EPS) {
		//			break;
		//		}
		dest.setTo(m1.x + ua * (m2.x - m1.x), m1.y + ua * (m2.y - m1.y));
		ret = true;
	} while (false);
	return ret;
}

void add(const FlPoint2 & a, const FlPoint2 & b, FlPoint2 &d) {
	d.x = a.x + b.x;
	d.y = a.y + b.y;
}
void difference(const FlPoint2 &b, const FlPoint2 &a, FlPoint2 &d) {
	d.setTo(b.x - a.x, b.y - a.y);
}
void addMultiple(const FlPoint2 &a, float mult, const FlPoint2 &b,
                 FlPoint2 &dest) {
	dest.x = a.x + mult * b.x;
	dest.y = a.y + mult * b.y;
}
void interpolate(const FlPoint2 & p1, const FlPoint2 &p2, float t,
                 FlPoint2 &d) {
	d.setTo(p1.x + t * (p2.x - p1.x), p1.y + t * (p2.y - p1.y));
}

void midPoint(const FlPoint2 &p1, const FlPoint2 &p2, FlPoint2 &d) {
	interpolate(p1, p2, .5f, d);
}

float distance(const FlPoint2 &a, const FlPoint2 &b) {
	return distance(a.x, a.y, b.x, b.y);
}

float distanceSq(float ax, float ay, float bx, float by) {
	float dx = bx - ax;
	float dy = by - ay;
	return dx * dx + dy * dy;
}

float distance(float ax, float ay, float bx, float by) {
	return sqrt(distanceSq(ax, ay, bx, by));
}

float distanceSq(const FlPoint2 &a, const FlPoint2 &b) {
	return distanceSq(a.x, a.y, b.x, b.y);
}

void add(const IPoint2 &a, const IPoint2 &b, IPoint2 &d) {
	d.x = a.x + b.x;
	d.y = a.y + b.y;
}

float distance(const IPoint2 &a, const IPoint2 &b) {
	return distance(a.x, a.y, b.x, b.y);
}
int distanceSq(int ax, int ay, int bx, int by) {
	int dx = bx - ax;
	int dy = by - ay;
	return dx * dx + dy * dy;
}

float distance(int ax, int ay, int bx, int by) {
	return sqrt(distanceSq(ax, ay, bx, by));
}
float distanceSq(const IPoint2 &a, const IPoint2 &b) {
	return distanceSq(a.x, a.y, b.x, b.y);
}

void difference(const IPoint2 &b, const IPoint2 &a, IPoint2 &d) {
	d.setTo(b.x - a.x, b.y - a.y);
}

float FlPoint3::normalize() {
	float lenSq = lengthSq();
	if (lenSq != 0 && lenSq != 1) {
		lenSq = sqrt(lenSq);
		float scale = 1 / lenSq;
		x *= scale;
		y *= scale;
		z *= scale;
	}
	return lenSq;
}

void interpolate(const FlPoint3 & a, const FlPoint3 & b, float mult,
                 FlPoint3 &dest) {
	dest.setTo(a.x + mult * (b.x - a.x), a.y + mult * (b.y - a.y),
               a.z + mult * (b.z - a.z));
}

void add(const FlPoint3 &a, const FlPoint3 &b, FlPoint3 &dest) {
	dest.x = a.x + b.x;
	dest.y = a.y + b.y;
	dest.z = a.z + b.z;
}
void addMultiple(const FlPoint3 &a, float mult, const FlPoint3 &b,
                 FlPoint3 &dest) {
	dest.x = a.x + mult * b.x;
	dest.y = a.y + mult * b.y;
	dest.z = a.z + mult * b.z;
}

float distance(const FlPoint3 & a, const FlPoint3 & b) {
	return distance(a.x, a.y, a.z, b.x, b.y, b.z);
}

float distanceSq(const FlPoint3 & a, const FlPoint3 & b) {
	return distanceSq(a.x, a.y, a.z, b.x, b.y, b.z);
}

float distanceSq(float x1, float y1, float z1, float x2, float y2, float z2) {
	x1 -= x2;
	y1 -= y2;
	z1 -= z2;
	return (x1 * x1 + y1 * y1 + z1 * z1);
}

float distance(float x1, float y1, float z1, float x2, float y2, float z2) {
	return sqrt(distanceSq(x1, y1, z1, x2, y2, z2));
}

void difference(const FlPoint3 & b, const FlPoint3 & a, FlPoint3 &d) {
	d.setTo(b.x - a.x, b.y - a.y, b.z - a.z);
}

void crossProduct(const FlPoint3 & a, const FlPoint3 & b, const FlPoint3 & c,
                  FlPoint3 &dest) {
	crossProduct(b.x - a.x, b.y - a.x, b.z - a.z, c.x - a.x, c.y - a.y,
                 c.z - a.z, dest);
}
float innerProduct(const FlPoint3 & s, const FlPoint3 & t) {
	return innerProduct(s.x, s.y, s.z, t.x, t.y, t.z);
}

void crossProduct(float x1, float y1, float z1, float x2, float y2, float z2,
                  FlPoint3 &dest) {
	dest.x = y1 * z2 - z1 * y2;
	dest.y = z1 * x2 - x1 * z2;
	dest.z = x1 * y2 - y1 * x2;
}
void add(const FlPoint3 &a, const FlPoint3 &b, FlPoint3 *dest) {
	dest->x = a.x + b.x;
	dest->y = a.y + b.y;
	dest->z = a.z + b.z;
}

void crossProduct(const FlPoint3 & a, const FlPoint3 & b, FlPoint3 &dest) {
	crossProduct(a.x, a.y, a.z, b.x, b.y, b.z, dest);
}

float innerProduct(float x1, float y1, float z1, float x2, float y2, float z2) {
	return x1 * x2 + y1 * y2 + z1 * z2;
}

void FlRect::add(float px, float py) {
	float x2 = max(endX(), px);
	float y2 = max(endY(), py);
	x = min(x, px);
	y = min(y, py);
	width = x2 - x;
	height = y2 - y;
}

IRect::IRect(const FlRect *r) {
	setTo((int) r->x, (int) r->y, (int) r->width, (int) r->height);
}
void IRect::add(int px, int py) {
	float x2 = max(endX(), px);
	float y2 = max(endY(), py);
	x = min(x, px);
	y = min(y, py);
	width = x2 - x;
	height = y2 - y;
}

#if DEBUG
String FlPoint2::toString(){
	char *s = debugStr();
	sprintf(s, "%s%s", d( x), d( y));
	return s;
}

String FlPoint3::toString() {
	char *s = debugStr();
	sprintf(s, "%s%s%s", d( x), d(y), d(z));
	return s;
}
String FlPoint4::toString() {
	char *s = debugStr();
	sprintf(s, "%s%s%s%s", d(x), d(y), d(z), d(w));
	return s;
}

String IPoint2::toString() const {
	char *s = debugStr();
	sprintf(s, "%s%s", d(x), d(y));
	return s;
    
}

String FlRect::toString() {
	char *s = debugStr();
	sprintf(s, "[x=%sy=%sw=%sh=%s] ", d(x), d(y), d(width), d(height));
	return s;
}
String IRect::toString() {
	char *s = debugStr();
	sprintf(s, "[x=%sy=%sw=%sh=%s] ", d(x), d(y), d(width), d(height));
	return s;
}

#endif

float angle(float a) {
	return modf(a + PI, PI * 2) - PI;
}

float angle2(float a) {
	float r = angle(a);
	if (r < 0)
		r += PI * 2;
	return r;
}

bool intersect(IRect &a, IRect &b, IRect &c) {
	int x1 = a.x;
	int y1 = a.y;
	int x2 = a.endX();
	int y2 = a.endY();
	x1 = max(x1, b.x);
	y1 = max(y1, b.y);
	x2 = min(x2, b.endX());
	y2 = min(y2, b.endY());
    
	c.setTo(x1, y1, x2 - x1, y2 - y1);
	return (c.width >= 0 && c.height >= 0);
}

// --------------------------------------------------------------------
// MARK: -
// MARK: FlMatrix
// --------------------------------------------------------------------

#undef Z
#define Z FlMatrix

void Z::apply(const FlPoint4 &pt, FlPoint4 &result) const {
	ASSERT(w == 4 && h == 4);
    
#undef M
#define M(n) (c[4*0 + n] * pt.x + c[4*1 + n] * pt.y + c[4*2+n] * pt.z + c[4*3+n] * pt.w)
    
	float x, y, z, w;
    
	x = M(0);
	y = M(1);
	z = M(2);
	w = M(3);
    
	result.x = x;
	result.y = y;
	result.z = z;
	result.w = w;
}

Z::Z(int height, int width) {
	w = width;
	h = height;
	c = new float[w * h];
}

Z::~Z() {
	delete[] c;
}

float Z::get(int row, int col) const {
	ASSERT(row >= 0 && row < h && col >= 0 && col < w);
	return c[col * h + row];
}

void Z::setToIdentity() {
	ASSERT(w==h);
	int s = w * h;
	for (int i = 0; i < s; i++)
		c[i] = 0;
	for (int j = 0; j < w; j++)
		set(j, j, 1);
}
void Z::set44(const float *coeff) {
	ASSERT(w == 4 && h == 4);
	int i = 0;
	for (int y = 0; y < 4; y++)
		for (int x = 0; x < 4; x++, i++)
			set(y, x, coeff[i]);
}

void Z::invert(FlMatrix &dest) const {
	ASSERT(w == 4 && h == 4);
    
	float *m = c;
    
	float wtmp[4][8];
	float *tmp;
    
	float m0, m1, m2, m3, s;
	float* r0, *r1, *r2, *r3;
    
	r0 = wtmp[0];
	r1 = wtmp[1];
	r2 = wtmp[2];
	r3 = wtmp[3];
    
	r0[0] = m[0 + 4 * 0];
	r0[1] = m[0 + 4 * 1];
	r0[2] = m[0 + 4 * 2];
	r0[3] = m[0 + 4 * 3];
	r0[4] = 1.0f;
	r0[5] = r0[6] = r0[7] = 0;
    
	r1[0] = m[1 + 4 * 0];
	r1[1] = m[1 + 4 * 1];
	r1[2] = m[1 + 4 * 2];
	r1[3] = m[1 + 4 * 3];
	r1[4] = r1[6] = r1[7] = 0;
	r1[5] = 1.0f;
    
	r2[0] = m[2 + 4 * 0];
	r2[1] = m[2 + 4 * 1];
	r2[2] = m[2 + 4 * 2];
	r2[3] = m[2 + 4 * 3];
	r2[6] = 1.0f;
	r2[4] = r2[5] = r2[7] = 0;
    
	r3[0] = m[3 + 4 * 0];
	r3[1] = m[3 + 4 * 1];
	r3[2] = m[3 + 4 * 2];
	r3[3] = m[3 + 4 * 3];
	r3[7] = 1.0f;
	r3[4] = r3[5] = r3[6] = 0.0f;
    
	/* choose pivot - or die */
	if (fabs(r3[0]) > fabs(r2[0])) {
		tmp = r3;
		r3 = r2;
		r2 = tmp;
	}
	if (fabs(r2[0]) > fabs(r1[0])) {
		tmp = r2;
		r2 = r1;
		r1 = tmp;
	}
	if (fabs(r1[0]) > fabs(r0[0])) {
		tmp = r1;
		r1 = r0;
		r0 = tmp;
	}
    
	/* eliminate first variable     */
	m1 = r1[0] / r0[0];
	m2 = r2[0] / r0[0];
	m3 = r3[0] / r0[0];
	s = r0[1];
	r1[1] -= m1 * s;
	r2[1] -= m2 * s;
	r3[1] -= m3 * s;
	s = r0[2];
	r1[2] -= m1 * s;
	r2[2] -= m2 * s;
	r3[2] -= m3 * s;
	s = r0[3];
	r1[3] -= m1 * s;
	r2[3] -= m2 * s;
	r3[3] -= m3 * s;
	s = r0[4];
	if (s != 0.0) {
		r1[4] -= m1 * s;
		r2[4] -= m2 * s;
		r3[4] -= m3 * s;
	}
	s = r0[5];
	if (s != 0.0) {
		r1[5] -= m1 * s;
		r2[5] -= m2 * s;
		r3[5] -= m3 * s;
	}
	s = r0[6];
	if (s != 0.0) {
		r1[6] -= m1 * s;
		r2[6] -= m2 * s;
		r3[6] -= m3 * s;
	}
	s = r0[7];
	if (s != 0.0) {
		r1[7] -= m1 * s;
		r2[7] -= m2 * s;
		r3[7] -= m3 * s;
	}
    
	/* choose pivot - or die */
	if (fabs(r3[1]) > fabs(r2[1])) {
		tmp = r3;
		r3 = r2;
		r2 = tmp;
	}
	if (fabs(r2[1]) > fabs(r1[1])) {
		tmp = r2;
		r2 = r1;
		r1 = tmp;
	}
    
	//if (r1[1] == 0.0f) MyMath.err("singular matrix");
    
	/* eliminate second variable */
	m2 = r2[1] / r1[1];
	m3 = r3[1] / r1[1];
	r2[2] -= m2 * r1[2];
	r3[2] -= m3 * r1[2];
	r2[3] -= m2 * r1[3];
	r3[3] -= m3 * r1[3];
	s = r1[4];
	if (0.0 != s) {
		r2[4] -= m2 * s;
		r3[4] -= m3 * s;
	}
	s = r1[5];
	if (0.0 != s) {
		r2[5] -= m2 * s;
		r3[5] -= m3 * s;
	}
	s = r1[6];
	if (0.0 != s) {
		r2[6] -= m2 * s;
		r3[6] -= m3 * s;
	}
	s = r1[7];
	if (0.0 != s) {
		r2[7] -= m2 * s;
		r3[7] -= m3 * s;
	}
    
	/* choose pivot - or die */
	if (fabs(r3[2]) > fabs(r2[2])) {
		tmp = r3;
		r3 = r2;
		r2 = tmp;
	}
    
	/* eliminate third variable */
	m3 = r3[2] / r2[2];
	r3[3] -= m3 * r2[3];
	r3[4] -= m3 * r2[4];
	r3[5] -= m3 * r2[5];
	r3[6] -= m3 * r2[6];
	r3[7] -= m3 * r2[7];
    
	/* last check */
	s = 1.0f / r3[3]; /* now back substitute row 3 */
	r3[4] *= s;
	r3[5] *= s;
	r3[6] *= s;
	r3[7] *= s;
    
	m2 = r2[3]; /* now back substitute row 2 */
	s = 1.0f / r2[2];
	r2[4] = s * (r2[4] - r3[4] * m2);
	r2[5] = s * (r2[5] - r3[5] * m2);
	r2[6] = s * (r2[6] - r3[6] * m2);
	r2[7] = s * (r2[7] - r3[7] * m2);
	m1 = r1[3];
	r1[4] -= r3[4] * m1;
	r1[5] -= r3[5] * m1;
	r1[6] -= r3[6] * m1;
	r1[7] -= r3[7] * m1;
	m0 = r0[3];
	r0[4] -= r3[4] * m0;
	r0[5] -= r3[5] * m0;
	r0[6] -= r3[6] * m0;
	r0[7] -= r3[7] * m0;
    
	m1 = r1[2]; /* now back substitute row 1 */
	s = 1.0f / r1[1];
	r1[4] = s * (r1[4] - r2[4] * m1);
	r1[5] = s * (r1[5] - r2[5] * m1);
	r1[6] = s * (r1[6] - r2[6] * m1);
	r1[7] = s * (r1[7] - r2[7] * m1);
	m0 = r0[2];
	r0[4] -= r2[4] * m0;
	r0[5] -= r2[5] * m0;
	r0[6] -= r2[6] * m0;
	r0[7] -= r2[7] * m0;
    
	m0 = r0[1]; /* now back substitute row 0 */
	s = 1.0f / r0[0];
	r0[4] = s * (r0[4] - r1[4] * m0);
	r0[5] = s * (r0[5] - r1[5] * m0);
	r0[6] = s * (r0[6] - r1[6] * m0);
	r0[7] = s * (r0[7] - r1[7] * m0);
    
	float *d = dest.c;
    
	d[0 + 4 * 0] = r0[4];
	d[0 + 4 * 1] = r0[5];
	d[0 + 4 * 2] = r0[6];
	d[0 + 4 * 3] = r0[7];
    
	d[1 + 4 * 0] = r1[4];
	d[1 + 4 * 1] = r1[5];
	d[1 + 4 * 2] = r1[6];
	d[1 + 4 * 3] = r1[7];
    
	d[2 + 4 * 0] = r2[4];
	d[2 + 4 * 1] = r2[5];
	d[2 + 4 * 2] = r2[6];
	d[2 + 4 * 3] = r2[7];
    
	d[3 + 4 * 0] = r3[4];
	d[3 + 4 * 1] = r3[5];
	d[3 + 4 * 2] = r3[6];
	d[3 + 4 * 3] = r3[7];
    
}

void Z::multiply(const FlMatrix &ma, const FlMatrix &mb, FlMatrix &md) {
    
	ASSERT(ma.w == mb.h && md.w == mb.w && md.h == ma.h);
    
	const float *a = ma.coeff();
	const float *b = mb.coeff();
    
	float *d = md.c;
	float tmp[4 * 4];
    
	ASSERT(md.w * md.h <= 4*4);
    
	if (md.c == ma.c || md.c == mb.c)
		d = tmp;
    
	int ch = ma.w;
	int k = 0;
	for (int y1 = 0, y1a = 0; y1 < ma.h; y1++, y1a += ch) {
		for (int x2 = 0; x2 < mb.w; x2++) {
			float s = 0;
			for (int x = 0, xa = x2; x < ch; x++, xa += mb.w) {
				s += a[y1a + x] * b[xa];
			}
			d[k++] = s;
		}
	}
	if (d != md.c) {
		for (int i = 0; i < k; i++)
			md.c[i] = d[i];
	}
}

void Z::setTo(const FlMatrix &src) {
	ASSERT(w == src.w && h == src.h);
	int sz = w * h;
	for (int i = 0; i < sz; i++)
		c[i] = src.c[i];
    
}

void Z::set(int row, int col, float f) {
	ASSERT(row >= 0 && col >= 0 && row < h && col < w);
	c[col * h + row] = f;
}

#if DEBUG
String Z::toString() {
	String &k = debugString();
	for (int i = 0; i < h; i++) {
		k.append("[");
		for (int x = 0; x < w; x++)
            k.append(d(get(i, x)));
		k.append("]\n");
	}
	return k;
}
#endif

void Z::getRotate(float ang) {
	ASSERT(w == 3 && h == 3);
    
	float cs = cos(ang), ss = sin(ang);
    
#undef M
#define M(row,col,val) c[col * h + row] = val
	M(0, 0, cs);
	M(0, 1, -ss);
	M(0, 2, 0);
	M(1, 0, ss);
	M(1, 1, cs);
	M(1, 2, 0);
	M(2, 0, 0);
	M(2, 1, 0);
	M(2, 2, 1);
}
void Z::getTranslate(const FlPoint3 &pt, bool neg) {
	ASSERT(w == 4 && h == 4);
    
	setToIdentity();
	float sign = neg ? -1 : 1;
    
	set(0, 3, pt.x * sign);
	set(1, 3, pt.y * sign);
	set(2, 3, pt.z * sign);
}
void Z::setToScale(float x, float y, float z) {
	//void FlMatrix::getScale(const FlPoint3 &pt) {
	ASSERT(w == 4 && h == 4);
	setToIdentity();
    
	set(0, 0, x);
	set(1, 1, y);
	set(2, 2, z);
}

void Z::setToTranslate(float x, float y, float z) {
	ASSERT(w == 4 && h == 4);
	setToIdentity();
    
	set(0, 3, x);
	set(1, 3, y);
	set(2, 3, z);
}

void Z::scale(float s, FlMatrix &dest) const {
	ASSERT(w == h && w == dest.w && w == dest.h);
	ASSERT(w <= 4);
    
	//  float *v = c;
	float d[16];
    
	int sz = w * h;
	for (int i = 0; i < sz; i++)
		d[i] = c[i];
    
	for (int i = 0; i < w - 1; i++)
		for (int j = 0; j < h - 1; j++)
			d[i * h + j] = c[i * h + j] * s;
    
	for (int i = 0; i < sz; i++)
		dest.c[i] = d[i];
}

// --------------------------------------------------------------------
// MARK: -
// MARK: 2D Operations
// --------------------------------------------------------------------

#define MUSTBE2D() ASSERT(w==3 && h==3)

void Z::apply(float x, float y, FlPoint2 &dest) const {
	MUSTBE2D();
	dest.setTo( //
               c[3 * 0 + 0] * x + c[3 * 1 + 0] * y + c[3 * 2 + 0], //
               c[3 * 0 + 1] * x + c[3 * 1 + 1] * y + c[3 * 2 + 1] //
               );
}

void Z::setToTranslate(float tx, float ty) {
	MUSTBE2D();
    
	setToIdentity();
    
	set(0, 2, tx);
	set(1, 2, ty);
}

void Z::setToScale(float x, float y) {
	MUSTBE2D();
	setToIdentity();
    
	set(0, 0, x);
	set(1, 1, y);
}

// ---------------------------------------------------------------------------
#undef C
#define C Random
// ---------------------------------------------------------------------------
C::C(uint seed) {
	mw_ = seed;
	mz_ = seed;
	rnd();
	rnd();
}
int C::rnd(uint maxVal) {
	return rnd() % maxVal;
}
int C::rnd() {
	mz_ = 36969 * (mz_ & 65535) + (mz_ >> 16);
	mw_ = 18000 * (mw_ & 65535) + (mw_ >> 16);
	int ret = ((mz_ << 16) + mw_) & 0x7fffffff;
	//printf("ret=$%08x\n",ret);
	return ret;
}
bool C::rndBool() {
	return rnd(2) == 1;
}
float C::randf(float range) {
	float v = rnd() * (range / MAX);
	return v;
}
float C::weighted() {
	return randf() * randf();
}
float C::randf() {
	return rnd() * (1.0f / MAX);
}

float C::randfs(float range) {
	return randf(range) - range * .5f;
}

//float ptDistanceToLine(FlPoint2 &pt, FlPoint2 &e0, FlPoint2 &e1 ) {
//  float bLength =  ::distance(e0, e1);
//  float dist;
//  if (bLength == 0) {
//    dist =  ::distance(pt, e0);
//   } else {
//  	float ax = pt.x - e0.x;
//    float ay = pt.y - e0.y;
//    float bx = e1.x - e0.x;
//    float by = e1.y - e0.y;
//
//    float crossProd = bx * ay - by * ax;
//
//    dist = fabs(crossProd / bLength);
//
//  }
//  return dist;
//}
float signedPtDistanceToLine(FlPoint2 &pt, FlPoint2 &e0, FlPoint2 &e1) {
	float bLength = ::distance(e0, e1);
	float dist;
	if (bLength == 0) {
		dist = ::distance(pt, e0);
	} else {
		float ax = pt.x - e0.x;
		float ay = pt.y - e0.y;
		float bx = e1.x - e0.x;
		float by = e1.y - e0.y;
        
		float crossProd = bx * ay - by * ax;
        
		dist = (crossProd / bLength);
        
	}
	return dist;
}

float positionOnSegment(FlPoint2 &pt, FlPoint2 &s0, FlPoint2 &s1) {
    
	float sx = s1.x - s0.x;
	float sy = s1.y - s0.y;
    
	float t = 0;
    
	float dotProd = (pt.x - s0.x) * sx + (pt.y - s0.y) * sy;
	if (dotProd != 0)
		t = dotProd / (sx * sx + sy * sy);
    
	return t;
}

float ptDistanceToSegment(FlPoint2 &pt, FlPoint2 &l0, FlPoint2 &l1,
                          float *tPtr) {
    
	float dist = 0;
	// calculate parameter for position on segment
	float t = positionOnSegment(pt, l0, l1);
    
	if (t < 0) {
		dist = ::distance(pt, l0);
	} else if (t > 1) {
		dist = ::distance(pt, l1);
	} else {
		dist = ptDistanceToLine(pt, l0, l1);
	}
	if (tPtr)
		*tPtr = t;
    
	return dist;
}

