#import "Base.h"
#import <map>
#import <cmath>
#import <iostream>
#import <climits>	// for INT_MIN, _MAX
#import <objc/runtime.h>


void sleepFor(float timeInSeconds) {
    [NSThread sleepForTimeInterval: timeInSeconds];
}



#if DEBUG
void truncate(String &s, int maxLen, bool addDots) {
	if (size(s) > maxLen) {
		if (addDots && maxLen > 5) {
			s.resize(maxLen - 3);
			s.append("...");
		} else
			s.resize(maxLen);
	}
}

// ... trying this again...

const char *d(id item, bool truncate)   {
    String &s = debugString();
    if (!item)
        s.assign("<null>");
    else {
        s = str(item);
    }
    if (truncate) {
        ::truncate(s,40,true);
    }
    return s.c_str();
}

/*
 Get name of object's class as a c-string
 > obj	object
 */
const char *className(id obj) {
	if (obj == nil)
		return "<nil>";
	return class_getName([obj class]);
}
#endif

String EMPTYSTRING("");

String &debugString() {
    
	static Vector<String> stringPool;
	static uint pIndex;
	const uint POOL_SIZE = 256;
	if (stringPool.size() == 0) {
		for (uint i = 0; i < POOL_SIZE; i++)
            stringPool.push_back(String(""));
	}
	pIndex = (pIndex + 1) % POOL_SIZE;
	String &s = stringPool[pIndex];
	s.clear();
	return s;
}

const char *simpleName(const char *f) {
    
	String &s = debugString();
	//char *s = debugStr();
    
	const char *f2 = f;
	int i;
	for (i = 0; f[i]; i++)
		if (f[i] == '/' || f[i] == '\\')
			f2 = f + i + 1;
    
	for (i = 0; f2[i]; i++) {
		char c = f2[i];
#if 0 // remove extension?
		if (c == '.')
            break;
#endif
		s += c;
		//	s[i] = c;
	}
	return s.c_str();
}

const char *dbStringFor(const char *str, uint value) {
	String &s = debugString();
	s.append("(");
	s.append(simpleName(str));
	char s2[40];
	sprintf(s2, " %d)", value);
	s.append(s2);
	return s.c_str();
    //	char *s = debugStr();
    //	sprintf(s, "(%s %d)", simpleName(str), value);
    //	return s;
}

void trim(String &s, bool fromFront, bool fromRear) {
	String w;
	uint src = 0;
	if (fromFront) {
		while (src < s.length() && s[src] <= ' ')
			src++;
	}
	while (src < s.length()) {
		w += s[src];
		src++;
	}
	if (fromRear) {
		src = w.length();
		while (src > 0 && s[src - 1] <= ' ')
			src--;
		w.resize(src);
	}
	s.assign(w);
}



const char *d(double db) {
	return d((float) db);
}

const char *d(float f) {
	char *s = debugStr();
    
	// this rounding is overflowing, if mag already large; why is it even required?
    //	f = round(f * 10000) / 10000.f;
    
	int v = round(f);
	if (v == f)
		sprintf(s, "% 5d      ", v);
	else {
		sprintf(s, "% 10.4f ", f);
        
		// remove all but one trailing zero
		int lastNonZero = 0;
		bool sawChars = false;
		int k = 0;
		for (; s[k]; k++) {
			char c = s[k];
			if (c == ' ') {
				if (sawChars)
					break;
				continue;
			}
			sawChars = true;
			if (c != '0') {
				lastNonZero = k;
				if (c == '.')
					lastNonZero++;
			}
		}
        
		for (k = lastNonZero + 1; s[k] && s[k] != ' '; k++)
			s[k] = ' ';
	}
	return s;
}

const char *d(int v) {
	char *s = debugStr();
	sprintf(s, "%4d ", v);
	return s;
}
const char *d(uint v) {
	char *s = debugStr();
	sprintf(s, "%4u ", v);
	return s;
}

const char *d(bool b) {
	return b ? "T" : "F";
}

const char *db(int bits, int nDig) {
	long bits2 = bits;
	String &s = debugString();
	for (int k = nDig - 1; k >= 0; k--) {
		s += (char) ((bits2 & (1 << k)) ? '1' : '.');
	}
	return s.c_str();
}

const char *d(const char *s) {
	if (s == null)
		s = "<null>";
	return s;
}

const char *padTo(String &str, int minLength) {
	while (str.length() < (uint) minLength)
		str += ' ';
	return str.c_str();
}

const char *d(const char *s, int fixWidth) {
	String &r = debugString();
	if (!s)
		r.append("<null>");
	else
		r.append(s);
	truncate(r, fixWidth, true);
	padTo(r, fixWidth);
	return r.c_str();
    
}

const char *d(String st) {
#if 1 // embed string within quotes?
    String &s2 = debugString();
    s2 += '"';
    s2.append(st);
    s2 += '"';
    //
    //	char *s = debugStr();
    //	sprintf(s, "\"%s\"", st.c_str());
	return s2.c_str();
#else
	return st.c_str();
#endif
}

const char *dv_(const char *varName, const char *value) {
	String &s = debugString();
	int len = strlen(varName);
	padTo(s, max(35 - len, 0));
	s.append(varName);
	s.append(" = ");
	s.append(value);
	return s.c_str();
}


const char *d2(const char *s) {
	if (!s)
		return "<null>";
	String &w = debugString();
    
	for (int i = 0;; i++) {
		char c = s[i];
		if (!c)
			break;
		if (w.length() >= 70) {
			w.append("...");
			break;
		}
		if (c < ' ') {
			switch (c) {
                case '\n':
                    w.append("\\n");
                    break;
                case '\t':
                    w.append("\\t");
                    break;
                case 0x0d:
                    w.append("\\m");
                    break;
                default: {
                    char work[20];
                    sprintf(work, "<#%d>", c);
                    w.append(work);
                }
                    break;
			}
		} else {
			w += c;
		}
	}
	return w.c_str();
}

static int strIndex;
#define MAX_STRS 100
static char work[DSTR_LEN * (MAX_STRS + 2)];

char *debugStr() {
    static int counter;
    counter++;
    // enable this line if looking for problem:
    //  ASSERT(counter != 19);
    
	static char *prevStr;
	if (prevStr) {
		if (prevStr[DSTR_LEN - 1]) {
			printf("\n\n\n*** debug string overflow!!!!  Counter=%d\n\n\n",counter);
			prevStr[DSTR_LEN - 1] = 0;
			printf("==> %s\n", prevStr);
			ASSERT(false);
		}
	}
    
	char *s = work + (strIndex * DSTR_LEN);
	strIndex++;
	if (strIndex == MAX_STRS)
		strIndex = 0;
	*s = 0;
	prevStr = s;
	return s;
}

// MARK: -
// MARK: one-time reporting (warn/unimp)

// map for messages reported once-only
static Set<String> msgSet;

const char * __report__(const char *fileAndLine, const char *msg,
                        const char *prefix) {
	String s("*** ");
	s.append(prefix);
	s.append(" ");
	s.append(fileAndLine);
	if (msg) {
		s.append(": ");
		padTo(s, 42);
		s.append(msg);
	}
    
	if (!msgSet.add(s)) {
		printf("%s\n", s.c_str());
	}
	return "";
}



const char *dhex(const void *bytes, int len) {
    
	String &w = debugString();
	char *work = debugStr();
    
    //	int crReq = false;
    
	const byte *bp = (const byte *) bytes;
    
	int proc = 0;
	while (proc != len) {
        
		sprintf(work, "%04x: ", proc);
		w.append(work);
        
		int chunk = std::min(len - proc, 16);
        
		for (int i = 0; i < 16; i++) {
			//	byte val = 0;
			strcpy(work, "   ");
			if (i < chunk) {
				byte val = bp[i + proc];
				if (val)
					sprintf(work, "%02x ", val);
			}
			w.append(work);
		}
        
		w.append(" | ");
		for (int i = 0; i < 16; i++) {
			char c = ' ';
			if (i < chunk) {
				byte val = bp[i + proc];
				if (val >= ' ')
					c = (char) val;
			}
			w += c;
		}
		w += '\n';
        
		proc += chunk;
	}
    
	return w.c_str();
}

// ---------------------------------------------------------------------------
#undef C
#define C MyException
// ---------------------------------------------------------------------------

C::C(const char *cause, const char *arg) {
	//DBGWARN
	//pr("constructing exception, cause=%s, arg=%s\n",d(cause),d(arg) );
    
	construct(cause, arg);
}

void C::construct(const char *cause, const char *arg) {
	msg_.append("*** Exception");
	if (arg) {
		msg_.append(" (");
		msg_.append(arg);
		msg_.append(")");
	}
	if (cause) {
		msg_.append(": ");
		msg_.append(cause);
	}
}

void C::throwIt() {
#if DEBUG
	printf("...about to throw:  %s\n", this->what());
    printf("\n");
#endif
    
    
#if IOS && DEBUG && 0
	[NSThread exit];
#endif
    
	throw *this;
}

void throwException(const char *cause, const char *arg) {
	//   pr(("throwException\n cause=[%s]\n   arg=[%s]\n",d(cause),d(arg) ));
    
	MyException(cause, arg).throwIt();
}

int C::report() {
	std::cerr << what() << '\n';
	return 1;
}



String c(NSString *str) {
    ASSERT(str);
    const char *st = [str UTF8String];
    return String(st);
}


String str(id obj) {
    ASSERT(obj);
    return c([obj description]);
}






#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

UIColor *c(Color  col) {
    return [UIColor colorWithRed: col.red() green: col.green() blue: col.blue() alpha: 1];
}

Color c(UIColor *col) {
    float r,g,b,a;
    [col getRed: &r green: &g blue: &b alpha: &a];
    Color ch(r,g,b);
    return ch;
}

#if DEBUG

// Debug dump functions for various IOS structures

char *d(  CGRect  r) {
    char *s = debugStr();
    sprintf(s,"CGRect origin=(%s,%s) size=(%s,%s)",
            d(r.origin.x),d(r.origin.y),d(r.size.width),d(r.size.height) );
    return s;
}
char *d(CGPoint  p) {
    char *s = debugStr();
    sprintf(s,"CGPoint (%s,%s)",
            d(p.x),d(p.y) );
    return s;
}
char *d(CGSize sz){
    char *s = debugStr();
    sprintf(s,"CGSize (%s,%s)",
            d(sz.width),d(sz.height) );
    return s;
    
}
char *d(UIEdgeInsets p) {
    
    char *s = debugStr();
    sprintf(s,"[   top:%2d   left:%2d bottom:%2d  right:%2d]",(int)p.top,(int)p.left,(int)p.bottom,(int)p.right);
    return s;
}

char *d( CGAffineTransform  p) {
    
    char *s = debugStr();
    sprintf(s,"[%s %s 0]\n[%s %s 0]\n[%s %s 1]\n",
            d(p.a),d(p.b),d(p.c),d(p.d),d(p.tx),d(p.ty) );
    return s;
}
#endif // DEBUG


NSMutableArray *arr(){
    return [NSMutableArray array];
}
Str *str() {
    return [Str  string];
}


Dict *dict(){
    return [Dict dictionary];
}


#if DEBUG_MEM_ALLOC

static int intFor(Dict *dict, const char * key) {
    NSString *s = c(key);
    NSNumber *nm = [dict objectForKey: s];
    int ret = 0;
    if (nm)
        ret = [nm intValue];
    return ret;
}
static void setIntFor(Dict *dict, const char *key, int val) {

    
    NSNumber *nm = [NSNumber numberWithInt:val];
    [dict setObject:nm forKey: c(key)];
}

void adjustAllocCounter(const char *name, int count, const char *file, int line){
    static Dict *ad;
    static Dict *dmax;
    if (!ad) {
        ad = [dict() retain];
        dmax = [dict() retain];
    }
    
    int v = intFor(ad,name) + count;
    setIntFor(ad,name,v);
    if (v < 0) {
        printf("*** ADJ by %2d to %3d for %s (called from %s)\n",count,v,name,dbStringFor(file,line));
        ASSERT(false);
    }

//    NSString *s = c(name);
//    
//    NSNumber *nm = [ad objectForKey: s];
//    if (!nm) {
//        nm =[NSNumber numberWithInt:0];
//    }
//    
//    int v = [nm intValue] + count;
//    NSNumber *n2 = [NSNumber numberWithInt:v];
//    
//    [ad setObject:n2 forKey:s];
//    if (v < 0) {
//        printf("*** ADJ by %2d to %3d for %s (called from %s)\n",count,v,name,dbStringFor(file,line));
//        ASSERT(false);
//    }
//
    int v2 = intFor(dmax,name);
    if (v2 < v) {
//    NSNumber *nm2 = [dmax objectForKey: s];
//    if (!nm2) {
//        [dmax setObject:n2 forKey:s];
//        nm2 = n2;
//    } else {
//         
//        if (  v > [nm2 intValue]) {
            printf("ADJ for %s now %3d (%s)\n",name,v,dbStringFor(file,line));
        setIntFor(dmax,name,v);
//            [dmax setObject: n2 forKey: s];
//        }
    }
    
//    if (v < 0 || v > 40) {
//        printf("*** ADJ by %2d to %3d for %s (called from %s)\n",count,v,name,dbStringFor(file,line));
//    }
    
}
#endif

FILE * my_fopen(const char *path, const char *mode) {
	NSString *path2 = [NSString stringWithCString: path encoding:NSASCIIStringEncoding];
	NSString *path3 = [[NSBundle mainBundle] pathForResource:  path2 ofType: nil];
	FILE *f = fopen([path3 cStringUsingEncoding:1], mode);
    ASSERT(f);
	return f;
}








