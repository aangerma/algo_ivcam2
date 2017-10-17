


#pragma once


// This vp_tlm_fifo has same interfaces as OSCI tlm_fifo (and is also compatible with CtoS TLM interfaces which have resets).
// The difference between OSCI tlm_fifo and this tlm_fifo is that this tlm_fifo uses no delta cycles for updates - instead,
// zero-time variable updates and immediate event notifications are used.

namespace cynw {
namespace vp_tlm {


template <class T>
class vp_tlm_fifo :
  public virtual cynw_tlm::tlm_get_peek_if<T>,
  public virtual cynw_tlm::tlm_put_if<T>,
  public sc_prim_channel
{
public:

    explicit vp_tlm_fifo( int size_ = 1 ) : sc_prim_channel( sc_gen_unique_name( "fifo" ) ) { init( size_ ); }

    explicit vp_tlm_fifo( const char* name_, int size_ = 16 ) : sc_prim_channel( name_ ) { init( size_ ); }

    virtual ~vp_tlm_fifo() { delete [] m_buf; }

    virtual T get(cynw_tlm::tlm_tag<T> *t = 0 ) { T c; get( c );  return c; }

    virtual void get( T& c) {
       if (num_elements == 0)
         wait(m_data_write_event);

	nb_get(c);
     }

    virtual bool nb_get( T& c) {
       if (!nb_can_get()) return false;

       c = m_buf[first];
       -- num_elements;
       first = (first + 1) % m_size;
       m_data_read_event.notify();
       return true;
    }

    virtual bool nb_can_get(cynw_tlm::tlm_tag<T> *t = 0) const { return num_elements != 0; }

    virtual const sc_event &ok_to_get( cynw_tlm::tlm_tag<T> *t = 0 ) const { return m_data_write_event; }

    virtual void put( const T& c) {
       if (num_elements == m_size)
         wait(m_data_read_event);

       nb_put(c);
     }

    virtual bool nb_put( const T& c) {
       if (!nb_can_put()) return false;

       m_buf[(first + num_elements) % m_size] = c;
       ++ num_elements;
       m_data_write_event.notify();
       return true;
    }

    virtual bool nb_can_put(cynw_tlm::tlm_tag<T> *t = 0) const { return num_elements != m_size; }

    virtual const sc_event& ok_to_put( cynw_tlm::tlm_tag<T> *t = 0 ) const { return m_data_read_event; }

    virtual void reset_get(cynw_tlm::tlm_tag<T> *t = 0) { num_elements = first = 0; }
    virtual void reset_put(cynw_tlm::tlm_tag<T> *t = 0) { num_elements = first = 0; }

    // peek interfaces are not implemented yet..

    virtual T               peek(cynw_tlm::tlm_tag<T>* t=0) const { sc_assert(false); T v; return v; }
    virtual void            peek(T &v) const { v = peek(); }

    virtual bool            nb_peek(T& v) const { sc_assert(false); return false; }
    virtual bool            nb_can_peek(cynw_tlm::tlm_tag<T>* t=0) const { sc_assert(false); return false; }
    virtual const sc_event& ok_to_peek (cynw_tlm::tlm_tag<T>* t=0) const { sc_assert(false); static sc_event e; return e; }



protected:
    void init( int sz) {
      m_size = sz;
      m_buf = new T[sz];
      num_elements = 0;
      first = 0;
    }

    T*  m_buf;			// the buffer
    int m_size;			// size of the fifo buffer
    int num_elements;	        // number of items in fifo
    int first;			// location of first item (i.e. the item that will be read on next get()
    sc_event m_data_read_event;
    sc_event m_data_write_event;

private:
    // disabled
    vp_tlm_fifo( const vp_tlm_fifo<T>& );
    vp_tlm_fifo& operator = ( const vp_tlm_fifo<T>& );
};

}; // namespace vp_tlm
}; // namespace cynw

