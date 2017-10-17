#ifndef _FSDB_TRACE_FILE_H_ 
#define _FSDB_TRACE_FILE_H_
#include "systemc.h"
class novasObj;
struct novas_ev_module;
namespace sc_dt
{
    class sc_bit;
    class sc_logic;
    class sc_bv_base;
    class sc_lv_base;
    class sc_signed;
    class sc_unsigned;
    class sc_int_base;
    class sc_uint_base;
    class sc_fxval;
    class sc_fxval_fast;
    class sc_fxnum;
    class sc_fxnum_fast;
}


class fsdb_trace_file: public sc_trace_file {
public:
#define DECL_TRACE_METHOD_A(tp)                                               \
    virtual void trace( const tp& object,                                     \
            const std::string& name );
#define DECL_TRACE_METHOD_B(tp)                                               \
    virtual void trace( const tp& object,                                     \
            const std::string& name,                                \
            int width );
    DECL_TRACE_METHOD_A( bool )
    DECL_TRACE_METHOD_A( sc_bit )
    DECL_TRACE_METHOD_A( sc_logic )

    DECL_TRACE_METHOD_B( unsigned char )
    DECL_TRACE_METHOD_B( unsigned short )
    DECL_TRACE_METHOD_B( unsigned int )
    DECL_TRACE_METHOD_B( unsigned long )
    DECL_TRACE_METHOD_B( char )
    DECL_TRACE_METHOD_B( short )
    DECL_TRACE_METHOD_B( int )
    DECL_TRACE_METHOD_B( long )
    DECL_TRACE_METHOD_B( sc_dt::int64 )
    DECL_TRACE_METHOD_B( sc_dt::uint64 )

    DECL_TRACE_METHOD_A( float )
    DECL_TRACE_METHOD_A( double )
    DECL_TRACE_METHOD_A( sc_dt::sc_int_base )
    DECL_TRACE_METHOD_A( sc_dt::sc_uint_base )
    DECL_TRACE_METHOD_A( sc_dt::sc_signed )
    DECL_TRACE_METHOD_A( sc_dt::sc_unsigned )
    DECL_TRACE_METHOD_A( sc_dt::sc_fxval )
    DECL_TRACE_METHOD_A( sc_dt::sc_fxval_fast )
    DECL_TRACE_METHOD_A( sc_dt::sc_fxnum )
    DECL_TRACE_METHOD_A( sc_dt::sc_fxnum_fast )

    DECL_TRACE_METHOD_A( sc_dt::sc_bv_base )
    DECL_TRACE_METHOD_A( sc_dt::sc_lv_base )
#undef DECL_TRACE_METHOD_A
#undef DECL_TRACE_METHOD_B

    virtual void trace( const unsigned int& object,
            const std::string& name,
            const char** enum_literals ) {}
    virtual void write_comment( const std::string& comment ){}
protected:
    virtual void cycle( bool delta_cycle ){}
public:
    void fsdb_trace(const double&, const std::string&);
    void fsdb_trace(const bool&, const std::string&);
    void fsdb_trace(const sc_bit &, const std::string &);
    void fsdb_trace(const sc_logic &, const std::string &);
    void fsdb_trace(const unsigned char &, const std::string &, int);
    void fsdb_trace(const unsigned short &, const std::string &, int);
    void fsdb_trace(const unsigned int &, const std::string &, int);
    void fsdb_trace(const unsigned long &, const std::string &, int);
    void fsdb_trace(const char &, const std::string &, int);
    void fsdb_trace(const short &, const std::string &, int);
    void fsdb_trace(const int &, const std::string &, int);
    void fsdb_trace(const long &, const std::string &, int);
    void fsdb_trace(const unsigned char &, const std::string &);
    void fsdb_trace(const unsigned short &, const std::string &);
    void fsdb_trace(const unsigned int &, const std::string &);
    void fsdb_trace(const unsigned long &, const std::string &);
    void fsdb_trace(const char &, const std::string &);
    void fsdb_trace(const short &, const std::string &);
    void fsdb_trace(const int &, const std::string &);
    void fsdb_trace(const long &, const std::string &);
    void fsdb_trace(const float &, const std::string &);
    void fsdb_trace(const sc_dt::sc_int_base &, const std::string &);
    void fsdb_trace(const sc_dt::sc_uint_base &, const std::string &);
    void fsdb_trace(const sc_dt::sc_signed &, const std::string &);
    void fsdb_trace(const sc_dt::sc_unsigned &, const std::string &);
    void fsdb_trace(const sc_dt::sc_fxval &, const std::string &);
    void fsdb_trace(const sc_dt::sc_fxval_fast &, const std::string &);
    void fsdb_trace(const sc_dt::sc_fxnum &, const std::string &);
    void fsdb_trace(const sc_dt::sc_fxnum_fast &, const std::string &);
    void fsdb_trace(const sc_dt::sc_bv_base &, const std::string &);
    void fsdb_trace(const sc_dt::sc_lv_base &, const std::string &);
    void fsdb_trace(novas_ev_module*, const std::string &);
    void set_time_unit(int) { }
    void set_time_unit(double,sc_core::sc_time_unit) { } 
    
    fsdb_trace_file(const char* filename);
    fsdb_trace_file(int nSwitchSize,const char* filename,int nFileAmount,const char* logfile=NULL);
    fsdb_trace_file();
    virtual ~fsdb_trace_file();

    void DumpModule(sc_object*,int);
    void DumpModule(sc_object*);
    void DumpModule(int);
    bool CreateTree(sc_object* obj);

    void SetDumpOff();
    void SetDumpOn();
    void CloseFile();
private:    
    novasObj *pNovasObj;
    char* pFileName;

};


template<class T> void 
fsdb_trace(fsdb_trace_file *tf,sc_in<T>& obj,const std::string &name){
    if(tf==NULL)
        return;
    if(tf->CreateTree((sc_object*)&obj)){
        const T& _obj = obj.read();
        tf->fsdb_trace(_obj,name);
    }
}
template<class T> void 
fsdb_trace(fsdb_trace_file *tf,sc_inout<T>& obj,const std::string &name){
    if(tf==NULL)
        return;
    if(tf->CreateTree((sc_object*)&obj)){
        const T& _obj = obj.read();
        tf->fsdb_trace(_obj,name);
    }
}

template<class T> void 
fsdb_trace(fsdb_trace_file *tf,sc_out<T>& obj,const std::string &name){
    if(tf==NULL)
        return;
    if(tf->CreateTree((sc_object*)&obj)){
        const T& _obj = obj.read();
        tf->fsdb_trace(_obj,name);
    }
}

template<class T> void 
fsdb_trace(fsdb_trace_file *tf,sc_signal<T>& obj,const std::string &name){
    if(tf==NULL)
        return;
    if(tf->CreateTree((sc_object*)&obj)){
        const T& _obj = obj.get_data_ref();
        tf->fsdb_trace(_obj,name);
    }
}

/****************************************/

template<int W> void 
fsdb_trace(fsdb_trace_file *tf,sc_signal_rv<W>& obj,const std::string &name){
    if(tf==NULL)
        return;
    if(tf->CreateTree((sc_object*)&obj))
        tf->fsdb_trace(obj.get_data_ref(),name);
}
template<int W> void 
fsdb_trace(fsdb_trace_file *tf,sc_out_rv<W>& obj,const std::string &name){
    if(tf==NULL)
        return;
    if(tf->CreateTree((sc_object*)&obj))
        tf->fsdb_trace(obj.read(),name);
}
template<int W> void 
fsdb_trace(fsdb_trace_file *tf,sc_in_rv<W>& obj,const std::string &name){
    if(tf==NULL)
        return;
    if(tf->CreateTree((sc_object*)&obj))
        tf->fsdb_trace(obj.read(),name);
}
template<int W> void 
fsdb_trace(fsdb_trace_file *tf,sc_inout_rv<W>& obj,const std::string &name){
    if(tf==NULL)
        return;
    if(tf->CreateTree((sc_object*)&obj))
        tf->fsdb_trace(obj.read(),name);
}

extern void fsdb_trace(fsdb_trace_file *tf,sc_clock& obj,const std::string &name);



/* == Task Definition ============= */
extern void fsdbDumpvars(fsdb_trace_file* fp ,int nLevel,sc_object& obj);
extern void fsdbDumpvars(fsdb_trace_file* fp ,int nLevel);
extern void fsdbDumpvars(fsdb_trace_file* fp ,sc_object& obj);
extern void fsdbDumpvars(fsdb_trace_file* fp);
extern void fsdbDumpOn(fsdb_trace_file* fp);
extern void fsdbDumpOff(fsdb_trace_file* fp);
extern void fsdbDumpOn();
extern void fsdbDumpOff();
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const bool& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const float& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const double& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const char& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const unsigned char& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const short& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const unsigned short& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const int& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const unsigned int& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const long& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const unsigned long& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_bit& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_logic& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_int_base& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_uint_base& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_signed& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_unsigned& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_bv_base& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_lv_base& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_event& d);
#ifdef SC_INCLUDE_FX
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_fxval& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_fxval_fast& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_fxnum& d);
extern void fsdbDumpvars(fsdb_trace_file* fp,int nLevel,const sc_fxnum_fast& d);
#endif
extern void fsdb_trace(fsdb_trace_file* fp,const bool& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const float& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const double& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const char& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const unsigned char& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const short& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const unsigned short& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const int& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const unsigned int& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const long& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const unsigned long& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_event& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_bit& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_logic& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_int_base& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_uint_base& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_signed& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_unsigned& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_bv_base& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_lv_base& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_fxval& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_fxval_fast& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_fxnum& d,const std::string &name);
extern void fsdb_trace(fsdb_trace_file* fp,const sc_dt::sc_fxnum_fast& d,const std::string &name);

extern "C" {
    void fsdbInteractive();
}



#endif


