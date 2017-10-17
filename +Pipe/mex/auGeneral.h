#include <math.h>
#include "mex.h"

#pragma warning(disable : 4996)

typedef unsigned char uint8;
typedef unsigned char byte;
typedef unsigned short uint16;
typedef unsigned int uint32;
typedef unsigned long long uint64;
typedef char int8;
typedef short int16;
typedef int int32;

static const uint8 cFlagsLdOnMask = uint8(1) << 0;
static const uint8 cFlagsCodeStartMask = uint8(1) << 1;
static const uint8 cFlagsScanDirMask = uint8(1) << 2;
static const uint8 cFlagsTxRxShift = 3;
static const uint8 cFlagsTxRxMask = uint8(3) << cFlagsTxRxShift;
static const uint8 cFlagsRoiMask = uint8(1) << 5;

static const uint8 cPixelFlagsScanDirMask = uint8(1) << 0;
static const uint8 cPixelFlagsTxRxShift = 1;
static const uint8 cPixelFlagsTxRxMask = uint8(3) << cPixelFlagsTxRxShift;
static const uint8 cPixelFlagsEOFMask = uint8(1) << 3;

inline uint8 flagsTxRxMode(uint8 flags) { return (flags & cFlagsTxRxMask) >> cFlagsTxRxShift; }
inline uint8 pixelFlagsTxRxMode(uint8 flags) { return (flags & cPixelFlagsTxRxMask) >> cPixelFlagsTxRxShift; }
inline uint8 clearPixelFlagsEOF(uint8 flags) { return (flags & ~cPixelFlagsEOFMask); }

// -------------------------------------------------------------------------------------------------------
// convert c type to mex enum type
// -------------------------------------------------------------------------------------------------------

template<class T>
class mxType {
public:
    static mxClassID classID() { return 0; }
    static bool isClass(const mxArray *pa) { return false; }
};

#define MX_TYPE(type, cid, isf)  template<>\
class mxType<type> { public:\
static mxClassID classID() { return cid; }\
static bool isClass(const mxArray *pa) { return isf(pa); }\
};

MX_TYPE(bool, mxLOGICAL_CLASS, mxIsLogical)
MX_TYPE(int8, mxINT8_CLASS, mxIsInt8)
MX_TYPE(uint8, mxUINT8_CLASS, mxIsUint8)
MX_TYPE(int16, mxINT16_CLASS, mxIsInt16)
MX_TYPE(uint16, mxUINT16_CLASS, mxIsUint16)
MX_TYPE(int32, mxINT32_CLASS, mxIsInt32)
MX_TYPE(uint32, mxUINT32_CLASS, mxIsUint32)
MX_TYPE(float, mxSINGLE_CLASS, mxIsSingle)
MX_TYPE(double, mxDOUBLE_CLASS, mxIsDouble)

inline
int mxClassSize(const mxArray *mx)
{
    mxClassID cid = mxGetClassID(mx);
    switch (cid) {
    case mxLOGICAL_CLASS:
        return 1;
    case mxCHAR_CLASS:
        return 2;
    case mxDOUBLE_CLASS:
        return 8;
    case mxSINGLE_CLASS:
        return 4;
    case mxINT8_CLASS:
        return 1;
    case mxUINT8_CLASS:
        return 1;
    case mxINT16_CLASS:
        return 2;
    case mxUINT16_CLASS:
        return 2;
    case mxINT32_CLASS:
        return 4;
    case mxUINT32_CLASS:
        return 4;
    case mxINT64_CLASS:
        return 8;
    case mxUINT64_CLASS:
        return 8;
    default:
        return 0;
    }
}

inline
void mxFieldErrorMessage(const char* errorId, const char* field)
{
    char strError[128];
    sprintf(strError, "Field '%s' in struct has a wrong type or does not exist", field);
    if (errorId == 0)
        mexErrMsgTxt(strError);
    else
        mexErrMsgIdAndTxt(errorId, strError);
}

template <class T>
inline
T mxScalar(const mxArray* mxs, const char* errorId = 0)
{
    if (!mxIsNumeric(mxs))
        mxFieldErrorMessage(errorId, "Parameter is not scalar");
    return T(mxGetScalar(mxs));
}


template <class T>
inline
T mxField(const mxArray* mxStruct, const char* field, const char* errorId = 0)
{
    const mxArray* mxField = mxGetField(mxStruct, 0, field);
    if (mxField == 0 || !mxIsNumeric(mxField))
        mxFieldErrorMessage(errorId, field);
    return T(mxGetScalar(mxField));
}

template <>
inline
bool mxField<bool>(const mxArray* mxStruct, const char* field, const char* errorId)
{
    const mxArray* mxField = mxGetField(mxStruct, 0, field);
    if (mxField == 0 || !(mxIsNumeric(mxField) || mxIsLogical(mxField)))
        mxFieldErrorMessage(errorId, field);
    return (mxGetScalar(mxField) != 0);
}

template <class T>
inline
const T* mxArrayField(const mxArray* mxStruct, const char* field, int size, const char* errorId = 0)
{
    const mxArray* mxField = mxGetField(mxStruct, 0, field);
    if (mxField == 0 || !mxType<T>::isClass(mxField))
        mxFieldErrorMessage(errorId, field);
    if (mxGetM(mxField) * mxGetN(mxField) != size) {
        char errStr[256];
        sprintf(errStr, "filed \'%s\' has a wrong size", field);
        mxFieldErrorMessage(errorId, errStr);
    }
    return (const T*)(mxGetData(mxField));
}

//template <>
//inine
//bool mxField<bool>(const mxArray* mxStruct, const char* field, const char* errorId = 0)
//{
//	const mxArray* mxField = mxGetField(mxStruct, 0, field);
//	if (mxField == 0)
//		mxFieldErrorMessage(field, errorId);
//	else if (mxIsNumeric(mxField))
//		return (mxGetScalar(mxField) != 0);
//	else if (mxIsLogical(mxField))
//		return (mxGetLogicals(mxField) != 0);
//	return false;
//}


inline
void ErrorFun(const char* name, bool cond)
{
    if (!(cond))
        mexErrMsgIdAndTxt("codeFilter:nrhs", name);
    //mexWarnMsgIdAndTxt("codeFilter:nrhs", name);
}

inline
void WarnFun(const char* name, bool cond)
{
    if (!(cond)) {
        static int nWarned = 5;
        
        if (nWarned != 0) {
            mexWarnMsgIdAndTxt("codeFilter:nrhs", name);
            --nWarned;
        }
    }
}

inline
void BreakFun(const char* name, bool cond)
{
    if (cond) {
        int a = 5;
        mexWarnMsgIdAndTxt("codeFilter:nrhs", name);
    }
}

#define _DEBUG_CHECK
#ifdef _DEBUG_CHECK
# define CHECK(name, cond) WarnFun("failed: " #name, cond)
# define BREAK(name, cond) BreakFun("failed: " #name, cond)
# define WARN(name, cond) WarnFun("failed: " #name, cond)
# define REQUIRE(name, cond) ErrorFun("failed: " #name, cond)
//void CHECK(name, cond) { if (!(cond)) mexErrMsgIdAndTxt("codeFilter:nrhs", __FILE__ " failed:" #name);}
#else
# define CHECK(name, cond) (void(0))
# define BREAK(name, cond) (void(0))
# define WARN(name, cond) (void(0))
# define REQUIRE(name, cond) (void(0))
#endif

class MexStruct {
public:
    MexStruct()
        : m_struct(0)
    {
        const char* structFields[] = { "" };
        mwSize dims[1] = { 1 };
        m_struct = mxCreateStructArray(1, dims, 0, structFields);
    }

    mxArray* mxStruct() const { return m_struct; }

    void add(const char* fieldName, double value) {
        int iField = mxAddField(m_struct, fieldName);
        mxSetFieldByNumber(m_struct, 0, iField, mxCreateDoubleScalar(value));
    }

    template <class T>
    T* add(const char* fieldName, int m, int n) {
        int iField = mxAddField(m_struct, fieldName);
        mxArray* mxa = mxCreateNumericMatrix(m, n, mxType<T>::classID(), mxREAL);
        mxSetFieldByNumber(m_struct, 0, iField, mxa);
        return (T*)mxGetData(mxa);
    }

private:
    mxArray* m_struct;
};

template<class T>
inline T min(T a1, T a2)
{
    return (a1 > a2) ? a2 : a1;
}

template<class T>
inline T max(T a1, T a2)
{
    return (a1 > a2) ? a1 : a2;
}

template <class T>
class Image {
public:
    Image()
        : m_data(0), m_w(0), m_h(0), m_allocSize(0) {}
    Image(T* data, size_t width, size_t height)
        : m_data(data), m_w(width), m_h(height), m_allocSize(0) {}
    Image(size_t width, size_t height)
        : m_data(0), m_w(width), m_h(height), m_allocSize(0)
    {
        m_allocSize = size();
        m_data = new T[m_allocSize];
    }

    ~Image() { if (m_allocSize != 0) delete m_data; }

    void set(T* data, size_t width, size_t height) {
        if (m_allocSize != 0) {
            delete m_data;
            m_allocSize = 0;
        }
        m_data = data;
        m_w = width;
        m_h = height;
    }
    void set(size_t width, size_t height) {
        m_w = width;
        m_h = height;
        if (width * height <= m_allocSize)
            return;
        else if (m_allocSize != 0)
            delete m_data;
        m_allocSize = size();
        m_data = new T[m_allocSize];
    }

    bool empty() const { return m_w == 0 || m_h == 0; }

    size_t width() const { return m_w; }
    size_t height() const { return m_h; }

    size_t size() const { return m_w * m_h; }

    void clear() { m_w = 0; m_h = 0; }

    const T& operator()(size_t x, size_t y) const {
        CHECK(Valid_x, 0 <= x && x < m_w);
        CHECK(Valid_y, 0 <= y && y < m_h);
        return m_data[index(x, y)];
    }
    T& operator()(size_t x, size_t y) {
        CHECK(Valid_x, 0 <= x && x < m_w);
        CHECK(Valid_y, 0 <= y && y < m_h);
        return m_data[index(x, y)];
    }

    const T& operator[](size_t i) const {
        CHECK(Valid, 0 <= i && i < size());
        return m_data[i];
    }
    T& operator[](size_t i) {
        CHECK(Valid, 0 <= i && i < size());
        return m_data[i];
    }

    const T* row(size_t y) const {
        CHECK(Valid_y, 0 <= y && y < m_h);
        return &m_data[size_t(y)*size_t(m_w)];
    }
    T* row(size_t y) {
        CHECK(Valid_y, 0 <= y && y < m_h);
        return &m_data[size_t(y)*size_t(m_w)];
    }

    void flipUD() {
        for (int y = 0; y < m_h/2; ++y)
            for (int x = 0; x < m_w; ++x)
                swap((*this)(x, y), (*this)(x, m_h-1-y));
    }

    size_t index(size_t x, size_t y) const { return y*m_w + x;  }

private:
    T* m_data;
    size_t m_w, m_h;
    size_t m_allocSize;

private:
    Image(const Image&);
};


template <class T>
class Image3D {
public:
    Image3D()
        : m_data(0), m_w(0), m_h(0), m_depth(0), m_allocSize(0) {}
    Image3D(T* data, size_t width, size_t height, size_t depth)
        : m_data(data), m_w(width), m_h(height), m_depth(depth), m_allocSize(0) {}
    Image3D(size_t width, size_t height, size_t depth)
        : m_data(0), m_w(width), m_h(height), m_depth(depth), m_allocSize(0)
    {
        m_allocSize = size();
        m_data = new T[m_allocSize];
    }

    ~Image3D() { if (m_allocSize != 0) delete m_data; }

    void set(T* data, size_t width, size_t height, size_t depth) {
        if (m_allocSize != 0) {
            delete m_data;
            m_allocSize = 0;
        }
        m_data = data;
        m_w = width;
        m_h = height;
        m_depth = depth;
    }
    void set(size_t width, size_t height, size_t depth) {
        m_w = width;
        m_h = height;
        m_depth = depth;
        if (width * height * depth <= m_allocSize)
            return;
        else if (m_allocSize != 0)
            delete m_data;
        m_allocSize = size();
        m_data = new T[m_allocSize];
    }

    bool empty() const { return m_w == 0 || m_h == 0; }

    size_t width() const { return m_w; }
    size_t height() const { return m_h; }
    size_t depth() const { return m_depth; }

    size_t size() const { return size_t(m_w) * size_t(m_h) * size_t(m_depth); }

    void clear() { m_w = 0; m_h = 0; }

    const T* operator()(size_t x, size_t y) const {
        CHECK(Valid_x, 0 <= x && x < m_w);
        CHECK(Valid_y, 0 <= y && y < m_h);
        return &m_data[(y*m_w + x)*m_depth];
    }
    T* operator()(size_t x, size_t y) {
        CHECK(Valid_x, 0 <= x && x < m_w);
        CHECK(Valid_y, 0 <= y && y < m_h);
        return &m_data[(y*m_w + x)*m_depth];
    }

    const T& operator()(size_t x, size_t y, size_t depth) const {
        CHECK(Valid_x, 0 <= x && x < m_w);
        CHECK(Valid_y, 0 <= y && y < m_h);
        CHECK(Valid_depth, 0 <= depth && depth < m_depth);
        return m_data[(y*m_w + x)*m_depth+depth];
    }
    T& operator()(size_t x, size_t y, size_t depth) {
        CHECK(Valid_x, 0 <= x && x < m_w);
        CHECK(Valid_y, 0 <= y && y < m_h);
        CHECK(Valid_depth, 0 <= depth && depth < m_depth);
        return m_data[(y*m_w + x)*m_depth + depth];
    }

    const T& operator[](size_t i) const {
        CHECK(Valid, 0 <= i && i < size());
        return m_data[i];
    }
    T& operator[](size_t i) {
        CHECK(Valid, 0 <= i && i < m_w * m_h * m_depth);
        return m_data[i];
    }

private:
    T* m_data;
    size_t m_w, m_h, m_depth;
    size_t m_allocSize;

private:
    Image3D(const Image3D&);
};

template <class T, int SizeExp>
class FIFO {
public:
    static const int cBufferLen = 1 << SizeExp;
    static const int cBufferLenMask = cBufferLen - 1;

public:
    FIFO() : m_start(0), m_end(0), m_size(0) {}

    bool full() const { return m_size == cBufferLen; } // next(m_end) == m_start
    bool empty() const { return m_size == 0; } // m_end == m_start
    int size() const { return m_size; }

    int push(T val) {
        CHECK(BufferIsNotFull, !full());
        m_buf[m_end] = val;
        const int index = m_end;
        m_end = next(m_end);
        ++m_size;
        return index;
    }

    int push() {
        CHECK(BufferIsNotFull, !full());
        const int index = m_end;
        m_end = next(m_end);
        ++m_size;
        return index;
    }

    T& get(int index) {
        CHECK(ValidFifoIndex, 0 <= index && index < cBufferLen);
        return m_buf[index];
    }
    const T& get(int index) const {
        CHECK(ValidFifoIndex, 0 <= index && index < cBufferLen);
        return m_buf[index];
    }

    T& operator[](int i) {
        CHECK(ValidIndex, 0 <= i && i < m_size);
        return m_buf[(i + m_start) & cBufferLenMask];
    }
    const T& operator[](int i) const {
        CHECK(ValidIndex, 0 <= i && i < m_size);
        return m_buf[(i + m_start) & cBufferLenMask];
    }

    int indexToOrder(int index) const {
        CHECK(ValidFifoIndex, 0 <= index && index < cBufferLen);
        const int i = (index - m_start) & cBufferLenMask;
        //CHECK(ValidOrderIndex, i < m_size);
        return i;
    }

    int getNextPushIndex() const { return m_end; }
    int getPopIndex() const { return m_start; }
    const T& getPopValue() const { return m_buf[m_start]; }

    T pop() {
        CHECK(BufferIsNotEmpty, !empty());
        T val = m_buf[m_start];
        m_start = next(m_start);
        --m_size;
        return val;
    }

    void pop(int iStart, int iEnd) {
        CHECK(ValidPopStartEnd, iStart != iEnd);
        CHECK(ValidPopStart, iStart == m_start);
        const int popSize = (iEnd > iStart) ? (iEnd - iStart) : (iEnd + cBufferLen - iStart);
        CHECK(ValidPopSize, popSize <= size());
        m_start = iEnd;
        m_size -= popSize;
        CHECK(ResSize, ((m_end > m_start) ? (m_end - m_start) : (m_end + cBufferLen - m_start)) == m_size);
    }

    static bool between(int iStart, int i, int iEnd) {
        if (iStart < iEnd)
            return iStart <= i && i < iEnd;
        else
            return iStart <= i || i < iEnd; // eq to !(iEnd <= i && i < iStart);
    }

    static int next(int i) { return (i + 1) & cBufferLenMask; }

private:
    T m_buf[cBufferLen];
    int m_start, m_end;
    int m_size;
};


/*
template <class T, int SizeExp = 10>
class FIFO {
public:
    FIFO() : m_start(0), m_end(0), m_size(0) {}

    static const int cBufferSize = 1 << SizeExp;

    bool full() const { return m_size == cBufferSize; } // next(m_end) == m_start
    bool empty() const { return m_size == 0; } // m_end == m_start
    int size() const { return m_size; }

    void write(T val) {
        CHECK(BufferIsNotFull, !full());
        m_buf[m_end] = val;
        m_end = next(m_end);
        ++m_size;
    }

    T read() {
        CHECK(BufferIsNotEmpty, !empty());
        T val = m_buf[m_start];
        m_start = next(m_start);
        --m_size;
        return val;
    }

private:
    static const int cBufferLenMask = cBufferSize - 1;
    static int next(int i) { return (i + 1) & cBufferLenMask; }

private:
    T m_buf[cBufferSize];
    int m_start, m_end;
    int m_size; // for debug
};
*/
