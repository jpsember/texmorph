#import <Foundation/Foundation.h>

#pragma once

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string>
#include <vector>

// If DEBUG hasn't been defined, do so...
#ifndef DEBUG
#define DEBUG TRUE
#endif

typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned int uint;
typedef std::string String;
#define Vector std::vector
typedef Vector<String> StringVector;
typedef Vector<int> IntVector;

extern String EMPTYSTRING;

#define null 0
#define FALSE 0
#define TRUE 1


inline int size(String &s) {
	return s.size();
}

// convenience method to get size of vector as int
template<class T>
int size(Vector<T> &v) {return (int)v.size();}

template<class T>
void deleteElement(Vector<T> &v, int index) {
	v.erase(v.begin() + index );
}
template<class T>
void insertElement(Vector<T> &v, int index, T &elem) {
	v.insert(v.begin()+index, elem);
}
template<class T>
bool containsElement(Vector<T> &v, const T &elem) {
	return std::find(v.begin(), v.end(), elem)!=v.end();
}
template<class T>
void pop(Vector<T> &v, T&elem) {
	elem = v.back();
	v.pop_back();
}
template<class T>
void pop(Vector<T> &v ) {
	v.pop_back();
}

/**
 * Given a filename (produced by __FILE__) and a line number,
 * print a more compact representation of the two (by eliminating all the paths preceding the
 * actual file)
 */
const char *dbStringFor(const char *str, uint value);

// Generate compact string from current file and line
#define __FILE_AND_LINE__ dbStringFor(__FILE__,__LINE__)

// PR always displays output regardless of the DEBUG setting, and always prefixes with file and line
#define PR(fmt, ...) printf(("%s " fmt), __FILE_AND_LINE__, ##__VA_ARGS__)



class MyException: public std::exception {
public:
	MyException(const char *cause, const char *arg = null);
	virtual ~MyException() throw () {
	}
	virtual const char* what() const throw () {
		return msg_.c_str();
	}
	virtual void throwIt();
    
#if DEBUG
	String toString() {
		return String(what());
	}
#endif
	int report();
    
protected:
	void construct(const char *cause, const char *arg);
	String msg_;
};
void throwException(const char *cause, const char *arg = null);

#if DEBUG
#define DSTR_LEN 400
/**
 Get c-style (zero terminated) string from pool; debug only.
 @return string; maximum capacity is 400 characters plus zero
 */
char *debugStr();

/**
 Get string from pool
 @return string
 */
String &debugString();

// The pr(...) macro does debug printing within a function, if the bool _DEBUG_PRINTING_ is true.

// The default value for _DEBUG_PRINTING_ is false.  This can be overridden (shadowed) by
// using the DBG macro at the start of a function body.

const bool _DEBUG_PRINTING_ = false;

// Place this macro at the start of a function body to enable debug printing pr(...) within the function
#define DBG const bool _DEBUG_PRINTING_ = true; (void)_DEBUG_PRINTING_;

#define DBGCLASS static const bool _DEBUG_PRINTING_ = true;

#define DBGIF(a) bool _DEBUG_PRINTING_ = (a); (void)_DEBUG_PRINTING_;

// This enables debug printing, and prints a warning to that effect
#define DBGWARN DBG warn("debug printing enabled");

// This enables debug printing, prints a warning, and displays the function name
#define DBGFN DBGWARN pr("------------------------------\n %s\n",df())

#define pr(...) {if (_DEBUG_PRINTING_) printf(__VA_ARGS__);}

// A quick-and-dirty way of debugging: prints the current file and line
#define HEY puts(__FILE_AND_LINE__);

// print variable name and description
#define V(var) {if (_DEBUG_PRINTING_) std::puts( dv(var));}

/**
 * Throw an exception, after printing the current location;
 * constructs a formatted string (using sprintf)
 */
#define die(a,...) { \
char *__s__ = debugStr(); \
sprintf(__s__,a,##__VA_ARGS__); \
printf("*** fatal error %s: %s\n",__FILE_AND_LINE__,__s__); \
throwException("fatal error"); \
}

const char * __report__(const char *fileAndLine, const char *msg,
                        const char *prefix);

#define warn(a,...)  { \
char *__s__ = debugStr(); \
sprintf(__s__,a,##__VA_ARGS__); \
__report__(__FILE_AND_LINE__,__s__,"warning      "); \
}
#define unimp(a,...)  { \
char *__s__ = debugStr(); \
sprintf(__s__,a,##__VA_ARGS__); \
__report__(__FILE_AND_LINE__,__s__,"unimplemented"); \
}

#define REPORTIF(a,b,...) {if (a) printf(b,##__VA_ARGS__); }
#define ASSERT(flag) {if (!(flag)) die("assertion failure");}
#define ASSERT2(flag,a,...) {if (!(flag)) die(a,##__VA_ARGS__);}
#define ERROR(a) die(a)
#define ERROR2(a,...) die(a,##__VA_ARGS__)

#define errorIf(cond) ASSERT(!(cond))
#define errorIf2(cond,a,...) ASSERT2(!(cond),a,##__VA_ARGS__)

void printWarnings();


template<class T> T& get(Vector<T> &v, int elem) {ASSERT((uint)elem < v.size()); return v[elem];}



typedef NSMutableArray Array;
Array *arr();

typedef NSMutableString Str;

// Construct an NSMutableString
Str *str();

typedef NSMutableDictionary Dict;
Dict *dict();


// Debug-only functions to convert objects to null-terminated strings, for
// convenient use in printf (or pr(...)) calls.  The idea is that d(x) will
// generate a string from any object x.
const char *d(int v);
const char *d(uint v);
const char *d(float f);
const char *d(double d);
const char *dang(float theta);
const char *d(id item, bool truncate = true);


inline const char *d(signed char c) {
    return d((int) c);
}
inline const char *d(size_t x) {
    return d((uint) x);
}

inline const char *d(word v) {
    return d((uint) v);
}
const char *d(const char *s, int fixWidth);

inline const char *d(String &s, int fixWidth) {
    return d(s.c_str(), fixWidth);
}

const char *d(bool b);
const char *d(const char *s);
const char *dhex(const void *data, int len);
inline const char *dhex(String s) {
    return dhex(s.c_str(), s.length());
}

const char *db(int bits, int nDig = 8);
const char *dv_(const char *varName, const char *value);
#define df() __FUNCTION__
#define dv(var) dv_(#var,d(var))

inline const char *d(char *s) {
    return d((const char *) s);
}
const char *d(String s);

inline const char *d(std::exception &e) {
    return e.what();
}

// Display pointer using symbolic name that is easier to read
const char *dp(const void *ptr);

/*
 Display string in human-readable format, escaping non-printables
 and truncating with '...' if its length is large
 */
const char *d2(const char *s);
inline const char *d2(const String &s) {
    return d2(s.c_str());
}

template<class T>
const char *d(Vector<T> &vec) {
    String &s = debugString();
    s += '[';
    for (uint i = 0; i<vec.size(); i++) {
        if (i != 0) s+=' ';
        s.append(d(vec[i]));
    }
    s += ']';
    return s.c_str();
}

/*
 Call object's toString() method to get debug description; uses
 pass-by-value semantics.  For large objects, or objects that don't support
 copy constructors, use the GENDUMP(...) macro to generate a version of d(...)
 using pass-by-reference semantics.
 */

template<class T>
const char *d(T x) {
    String &s = debugString();
    s.assign(x.toString());
    return s.c_str();
}

#define GENDUMP(CLASS) \
inline const char *d(CLASS &object) { \
String &s = debugString(); \
s.assign(object.toString()); \
return s.c_str(); \
}

template<class T>
const char *d(T *x) {
    if (!x)
        return "<null>";
    return d(*x);
}

#endif

// When converting to/from Objective-C objects, use 'c' where possible.

/**
 Convert Obj-C string to UTF-8 string
 */
String c(NSString *str);

/**
 Convert Objective-c object to UTF-8 string, by calling its description method
 */
String str(id obj);

/*
 Construct an Objective-C string from a c-string (assumed to be in UTF-8)
 */

inline NSString *c(const char *str) {return [NSString stringWithUTF8String: str];}
inline NSString *c(String src) {return c(src.c_str()); }

// Construct an NSMutableString
inline NSMutableString *buildns() { return [NSMutableString stringWithCapacity: 20];}
inline NSMutableString *buildns(NSString *source) {return [NSMutableString stringWithString:source];}

#if DEBUG
inline const char *d(NSObject &itemRef, bool truncate = true) {
    return d(&itemRef, truncate);
}
#endif

inline id verifyNotNil(id val) {errorIf(!val); return val;}
/*
 Build a new object of a class, without owning it;
 generates the following code:
 [[Class new] autorelease]
 */
#define build(C) verifyNotNil([[C new] autorelease])



// --------------------------------------------------------------------
// MARK: -
// MARK: MySet (wrapper class for std::set)

#include <iterator>
#include <set>

/**
 * Wrapper class for STL std::set.
 */
template<class T, class Compare = std::less<T> >
class Set {
    
public:
    
	Set() {
		iterValid_ = false;
	}
    
	/*
	 * Determine if set contains an item
	 * > item
	 * < true if set contains item
	 */
	bool contains(const T &item) const {
		Iterator it = set_.find(item);
		return it != set_.end();
	}
    
	uint size() const {
		return set_.size();
	}
    
	bool isEmpty() const {
		return size() == 0;
	}
	/*
	 * Add item to set.  Sets iterator to location of item (or
	 * existing item, if it was already in the set)
	 * > item
	 * < true if item was already in set
	 */
	bool add(const T &value) {
		iterValid_ = true;
		std::pair<Iterator, bool> ret = set_.insert(value);
		iter_ = ret.first;
        
		return !ret.second;
	}
    
	void addAll(const std::vector<T> &src) {
		set_.insert(src.begin(), src.end());
	}
    
	void addAll(const Set<T, Compare> &src) {
		set_.insert(src.set_.begin(), src.set_.end());
	}
    
	void setTo(const Set<T, Compare> &src) {
		set_ = src.set_;
	}
    
	/*
	 * Remove item from set
	 * > item
	 * < true if item was in set
	 */
	bool remove(const T &item) {
		iterValid_ = false;
		size_t nRem = set_.erase(item);
		return (nRem != 0);
	}
    
	/*
	 * Clear all items from set
	 */
	void clear() {
		set_.clear();
		iterValid_ = false;
	}
    
	/*
	 * Reset iterator to start of set
	 * < true if another item exists
	 */
	bool beginIter() {
		iterValid_ = true;
		iter_ = set_.begin();
		return hasNext();
	}
    
	/**
	 * Find first element not less than a particular element;
	 * start iterating from that point
	 * < true if another element exists
	 */
	bool lowerBound(const T &item) {
		iterValid_ = true;
		iter_ = set_.lower_bound(item);
		return hasNext();
	}
    
	/*
	 * Determine if another item exists (during iteration)
	 */
	bool hasNext() const {
		ensureIterValid();
		return iter_ != set_.end();
	}
    
	/*
	 * Return next item in set (during iteration)
	 */
	T next() {
		if (!hasNext())
			throwException("no next element");
		return *(iter_++);
	}
    
	/*
	 * Return first item from set
	 */
	T removeFirst() {
		T val = first();
		set_.erase(val);
		return val;
	}
    
	T first() {
		beginIter();
		return next();
	}
    
private:
	void ensureIterValid() const {
		if (!iterValid_)
			throwException("invalid iterator");
	}
    
	typedef std::set<T, Compare> OurSet;
	OurSet set_;
	typedef typename OurSet::iterator Iterator;
	Iterator iter_;
	bool iterValid_;
};

template<class T>
void copy(Set<T> &src, std::vector<T> &dest) {
	dest.clear();
	src.beginIter();
	while (src.hasNext())
		dest.push_back(src.next());
}

#if DEBUG
template<class T>
const char *d(Set<T> &set) {
	String &s = debugString();
	s += '[';
	int i = 0;
	for (set.beginIter(); set.hasNext(); i++) {
		T key = set.next();
		if (i != 0)
			s += ' ';
		s.append(d(key));
	}
	s += ']';
	return s.c_str();
}
#endif

// --------------------------------------------------------------------
// MARK: -
// MARK: MyMap, a wrapper for std::map

#include <map>

/**
 * Wrapper for std::map class.
 */
template<class KEY, class VALUE, class COMPARE = std::less<KEY> >
class Map {
public:
	Map() {
		init();
	}
	/**
	 * Get value associated with key
	 * @param key
	 * @param value where to store the value, if key was found
	 * @param mustExist if true, throws exception if no key is found
	 * @return true if key was found
	 */
	bool get(const KEY &key, VALUE &value, bool mustExist = false) const {
        
		typename OurMap::const_iterator iter = map_.find(key);
        
		bool found = iter != map_.end();
		if (found)
			value = iter->second;
		else if (mustExist) {
			throwException("key not in map");
		}
		return found;
	}
    
	VALUE get(const KEY &key) const {
		VALUE val;
		get(key, val, true);
		return val;
	}
    
	/**
	 * Get number of keys in map
	 * @return size of map
	 */
	uint size() const {
		return map_.size();
	}
    
	/*
	 * Store key/value pair
	 * > key
	 * > value
	 */
	void put(const KEY &key, const VALUE &value) {
		map_[key] = value;
	}
    
	/*
	 * Remove key/value
	 * > key
	 * > valPtr if not null, and map contained key/value, value returned here
	 * > mustExist if true, and key not in map, throws exception
	 * < true if key/value was in the map (and has been removed)
	 */
	bool remove(const KEY &key, VALUE *valPtr = null, bool mustExist = false) {
		bool removed = false;
        
		typename OurMap::iterator iter = map_.find(key);
		if (iter != map_.end()) {
			if (valPtr)
				*valPtr = iter->second;
			map_.erase(iter);
			removed = true;
		} else if (mustExist) {
			throwException("key not in map");
		}
		return removed;
	}
    
	/*
	 * Clear all key/value pairs
	 */
	void clear() {
		map_.clear();
	}
    
	/*
	 * Reset iterator to start of map
	 * < true if another key exists
	 */
	bool beginIter() {
		iterValid_ = true;
		iter_ = map_.begin();
		return hasNext();
	}
    
	/**
	 * Find first key not less than a particular key;
	 * start iterating from that point
	 * < true if another key exists
	 */
	bool lowerBound(const KEY &key) {
		iterValid_ = true;
		iter_ = map_.lower_bound(key);
		return hasNext();
	}
    
	/*
	 * Determine if another item exists (during iteration)
	 */
	bool hasNext() const {
		ensureIterValid();
		return iter_ != map_.end();
	}
    
	/*
	 * Return next key in map (during iteration)
	 * < key where to store key
	 * > val if not null, points to location where value is to be returned
	 */
	void next(KEY &key, VALUE &val) {
		next(key, &val);
	}
    
	/*
	 * Return next key in map (during iteration)
	 * < key where to store key
	 * > val if not null, points to location where value is to be returned
	 */
	void next(KEY &key) {
		next(key, (VALUE *) 0);
	}
    
	bool containsKey(const KEY &key) const {
		typename OurMap::const_iterator iter = map_.find(key);
		return iter != map_.end();
	}
    
private:
	void init() {
		iterValid_ = false;
	}
    
	void next(KEY &key, VALUE *val) {
		if (!hasNext())
			throwException("no next element");
        
		key = iter_->first;
		if (val)
			*val = iter_->second;
		iter_++;
	}
    
	void ensureIterValid() const {
		if (!iterValid_)
			throwException("invalid iterator");
	}
    
	typedef std::map<KEY, VALUE, COMPARE> OurMap;
	OurMap map_;
	typedef typename OurMap::iterator Iterator;
	Iterator iter_;
	bool iterValid_;
};

#define DEBUG_MEM_ALLOC 0

#if DEBUG_MEM_ALLOC
void adjustAllocCounter(const char *name, int count, const char *file, int line);
#define ADJALLOC(name,count) adjustAllocCounter(name,count,__FILE__,__LINE__)
#else
#define ADJALLOC(n,c)
#endif

// Release an objective-c pointer, and clear it to nil
#define rel(x) { [x release]; x = nil;}

// Delete a C++ object if its pointer is not null; clear ptr
#define del(a) { if (a) { ADJALLOC("alloc",-1); delete a; a = 0;}}

#define newobj(a,b)  a = new b; ADJALLOC("alloc",1);






#include "MyMath.h"

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>






#if DEBUG
char *d(CGRect r);
char *d(CGPoint  p);
char *d(const CGAffineTransform  p);
char *d(CGSize sz);
char *d(UIEdgeInsets p);
#endif

// Conversions between Quartz elements and our equivalent counterparts


inline CGRect  c(FlRect  r) {
    return CGRectMake(r.x,r.y,r.width,r.height);
}

inline FlRect c(CGRect  r) {
    return *(FlRect *)(&r);
}
inline CGSize  cgsize(FlPoint2  pt) {
    return *(CGSize *)&pt;
}
inline CGSize cgsize(IPoint2  pt) {
    return CGSizeMake(pt.x,pt.y);
}

inline IRect ci(CGRect r) {
    return IRect(r.origin.x,r.origin.y,r.size.width,r.size.height);
}

inline FlPoint2   c(CGSize   s) {
    return *(FlPoint2 *)(&s);
}
inline IPoint2 ci(CGSize   s) {
    return IPoint2(s.width,s.height);
}

inline CGRect c(IRect r) {
    return CGRectMake(r.x,r.y,r.width,r.height);
}

inline CGPoint  c(FlPoint2  r) {
    return *(CGPoint *)(&r);
}
inline FlPoint2  c(CGPoint  r) {
    return *(FlPoint2 *)(&r);
}
inline CGPoint c(IPoint2 r) {
    return CGPointMake(r.x,r.y);
}
inline IPoint2 ci(CGPoint p) {
    return IPoint2(p.x,p.y);
}


/**
 A lightweight wrapper for array of floats r,g,b,a
 */
class Color {
public:
	Color() {
		rgba_[0] = 0;
		rgba_[1] = 0;
		rgba_[2] = 0;
		rgba_[3] = 1;
	}
	Color(float r, float g, float b, float a = 1.0f) {
		rgba_[0] = r;
		rgba_[1] = g;
		rgba_[2] = b;
		rgba_[3] = a;
	}
    float* rgba()  {
		return rgba_;
	}
	float red() const {
		return rgba_[0];
	}
	float green() const {
		return rgba_[1];
	}
	float blue() const {
		return rgba_[2];
	}
	float alpha() const {
		return rgba_[3];
	}
	void setTo(float r = 0, float g = 0, float b = 0, float a = 1) {
		rgba_[0] = r;
		rgba_[1] = g;rgba_[2] = b;rgba_[3] = a;
	}
#if DEBUG
    String toString();
    bool defined() {
        return red() || green() || blue() || (alpha()!=1);
    }
#endif
    bool equals(Color &src);
private:
	float rgba_[4];
};

inline Color grey(float intensity) {
	return Color(intensity,intensity,intensity);
}


UIColor *c(Color col);
Color c(UIColor *col);


// User should supply this function:

// Get the main application view; construct it if necessary
id appView( );

#define FPS 60

/*
 * Open file.  Use this instead of the standard fopen(..) method.
 */
FILE *my_fopen(const char *path, const char *mode);




