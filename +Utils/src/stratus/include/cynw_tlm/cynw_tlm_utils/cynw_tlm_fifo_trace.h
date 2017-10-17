// ****************************************************************************
// ctos_tlm_fifo_trace.h
//
// This file contains support for tracing for the ctos_tlm::tlm_fifo* classes.
//
// 
// ****************************************************************************
#ifndef CYNW_TLM_FIFO_TRACE_HEADER
#define CYNW_TLM_FIFO_TRACE_HEADER
#include "sysc/communication/sc_communication_ids.h"
#include "sysc/cosim/sc_cosim.h"
#include "sysc/cosim/sc_txp.h"


#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw_tlm
{

// *****************************************************************************
// This class is repsponsible for allowing to trace a fifo. 
// *****************************************************************************
template<typename T>
class tlm_fifo_trace: public sc_object {
  public: 
			    tlm_fifo_trace(const tlm_fifo_internals_if<T> *fifo);
    virtual bool	    ncsc_supports_deposit() const { return false; }
    virtual sc_event	    *ncsc_probe_event(); 
    virtual bool	    ncsc_print_value(::std::ostream &os, ncsc_value_mode_t mode) const;
    virtual bool	    ncsc_deposit_value(const char *s, bool force) {return false;};
    virtual const char	    *ncsc_print() const { return sc_object::ncsc_print(); }
    virtual bool	    ncsc_needs_sequence_probe() const { return true; }
    virtual bool	    ncsc_is_transaction_probe() const { return true; }
    virtual void	    ncsc_write_transaction(sc_txp *txp);
    virtual bool	    ncsc_supports_value() const {return true;};
    virtual bool	    ncsc_supports_force() const {return false;};
    virtual bool	    ncsc_supports_value_change_callback() const {return true;};
    void		    trace_get(const T &v);
    void		    trace_put(const T &v);
    void		    trace_reset_get();
    void		    trace_reset_put();

    const tlm_fifo_internals_if<T> *m_fifo;
    sc_event                m_probe_event;
    std::string 	    m_probe_string;

    std::string             m_last_op;
    std::string             m_proc_name;
    T                       m_last_val;
    int			    m_rc;
    int			    m_wc;
    const int		    m_size;
    const int		    m_size2;
};

// *****************************************************************************
// This is the constructor of the tlm_fifo_trace class.
// *****************************************************************************
template <typename T>
inline
tlm_fifo_trace<T>::tlm_fifo_trace(const tlm_fifo_internals_if<T>   *fifo)
:   sc_object("trace"),
    m_fifo(fifo),
    m_rc(0),
    m_wc(0),
    m_size(fifo->internal_size()),
    m_size2(2 * fifo->internal_size())
{
}


template <typename T>
inline
sc_event* 
tlm_fifo_trace<T>::ncsc_probe_event() 
{
    return &m_probe_event;
}



template <typename T>
inline 
void 
tlm_fifo_trace<T>::ncsc_write_transaction(sc_core::sc_txp *txp) 
{
#ifndef STRATUS
    OStrStream os;
    os << m_last_val << std::ends;
    txp->record_attribute("op", m_last_op);  
    txp->record_attribute("by_proc", m_proc_name);
    if (m_last_op == std::string("GET")) {
	txp->record_attribute("count", m_rc);
	txp->record_attribute("value_read", OStrStream_string(os));
	txp->record_attribute("size", m_fifo->internal_num_filled_slots(true));
    } else if (m_last_op == std::string("PUT")) {
	txp->record_attribute("count", m_wc);
	txp->record_attribute("value", OStrStream_string(os));
	txp->record_attribute("size", m_fifo->internal_num_filled_slots(true));
    }
#endif
};

template <typename T>
inline 
void 
tlm_fifo_trace<T>::trace_get(const T& v)
{
#ifndef STRATUS
    // Method ncsc_write_transaction will read the attributes set by this   
    // function and display them in simvisions' wave diagram.
    sc_process_b* curr_proc = sc_get_curr_process();
    std::string proc_name = curr_proc ? curr_proc->name() : "<UNKNOWN>";
    m_last_op   = "GET";
    m_proc_name = proc_name;
    m_last_val  = v;
    m_rc++;
    
    // For NCSC_TRANSACTION printing:
    // dump into stream and then extract string out of it
    OStrStream Sstream;
    Sstream << "GET # " << m_fifo->internal_num_pending_gets() 
	    << " by '" << proc_name
            << "', value read='" << v 
	    << "', size=" << m_fifo->internal_num_filled_slots(true) << '\0';
    m_probe_string = OStrStream_string(Sstream);

    m_probe_event.notify();
#endif
}

template <typename T>
inline 
void 
tlm_fifo_trace<T>::trace_put(const T& v)
{
#ifndef STRATUS
    // Method ncsc_write_transaction will read the attributes set by this function  
    // function and display them in simvisions' wave diagram.
    sc_process_b* curr_proc = sc_get_curr_process();
    std::string proc_name = curr_proc ? curr_proc->name() : "<UNKNOWN>";
    m_last_op   = "PUT";
    m_proc_name = proc_name;
    m_last_val  = v;
    m_wc++;
    
    // For NCSC_TRANSACTION printing: 
    // dump into stream and then extract string out of it.
    OStrStream Sstream;
    Sstream << "PUT # " << m_fifo->internal_num_pending_puts() 
	    << " by '" << proc_name
            << "', value written='" << v 
	    << "', size=" << m_fifo->internal_num_filled_slots(true) << '\0';
    m_probe_string = OStrStream_string(Sstream);
    
    m_probe_event.notify();
#endif
}



template <typename T>
inline 
void 
tlm_fifo_trace<T>::trace_reset_get()
{
#ifndef STRATUS
    // Method ncsc_write_transaction will read the attributes set by this function  
    // function and display them in simvisions' wave diagram.
    sc_process_b* curr_proc = sc_get_curr_process();
    std::string proc_name = curr_proc ? curr_proc->name() : "<UNKNOWN>";
    m_last_op   = "RESET_GET";
    m_proc_name = proc_name;
    
    // For NCSC_TRANSACTION printing: 
    // dump into stream and then extract string out of it.
    OStrStream Sstream;
    Sstream << "RESET_GET by '" << proc_name
            << "', size=" << m_fifo->internal_num_filled_slots(true) << '\0';
    m_probe_string = OStrStream_string(Sstream);
    
    m_probe_event.notify();
#endif
}



template <typename T>
inline 
void 
tlm_fifo_trace<T>::trace_reset_put()
{
#ifndef STRATUS
    // Method ncsc_write_transaction will read the attributes set by this function  
    // function and display them in simvisions' wave diagram.
    sc_process_b* curr_proc = sc_get_curr_process();
    std::string proc_name = curr_proc ? curr_proc->name() : "<UNKNOWN>";
    m_last_op   = "RESET_PUT";
    m_proc_name = proc_name;
    
    // For NCSC_TRANSACTION printing: 
    // dump into stream and then extract string out of it.
    OStrStream Sstream;
    Sstream << "RESET_PUT by '" << proc_name
            << "', size=" << m_fifo->internal_num_filled_slots(true) << '\0';
    m_probe_string = OStrStream_string(Sstream);
    
    m_probe_event.notify();
#endif
}



template <typename T>
inline
bool 
tlm_fifo_trace<T>::ncsc_print_value(::std::ostream& os, ncsc_value_mode_t mode) const
{   
    switch (mode) {
      case sc_core::NCSC_VERBOSE: 
	{
	    os << "slots: " << m_size << std::endl;

	    if (m_fifo->internal_num_pending_puts() || m_fifo->internal_num_pending_gets()) {
		// there are some pending reads and writes, print 2 sizes
		os << "size after pending gets and puts: "
		   << m_fifo->internal_num_filled_slots(true) << std::endl;
		os << "size before pending gets and puts: "
		   << m_fifo->internal_num_filled_slots(false) << std::endl;
	    } else { // print just one size
		os << "size: " << m_fifo->internal_num_filled_slots(true) << std::endl;
	    }

	    os << "number of elements available for getting: "
	       << m_fifo->internal_num_available_for_getting() << std::endl;
	    os << "number of free slots available for putting: "
	       << m_fifo->internal_num_available_for_putting() << std::endl;

	    if (m_fifo->internal_num_filled_slots(true) > 0 || m_fifo->internal_num_filled_slots(false) > 0) {
		// some contents will be printed
		os << "Contents (top to bottom):" << std::endl;
	    }

	    // print contents in 3 sections
	    // 1. pending reads in this eval
	    // 2. stable contents
	    // 3. pending writes in this eval

	    int bounds[4];
	    bounds[0] = m_fifo->internal_extended_read_index(false);

	    bounds[1] = m_fifo->internal_extended_read_index(true);
	    (bounds[1] >= bounds[0]) || (bounds[1] += m_size2);
	      
	    bounds[2] = m_fifo->internal_extended_write_index(false);
	    (bounds[2] >= bounds[1]) || (bounds[2] += m_size2);
	      
	    bounds[3] = m_fifo->internal_extended_write_index(true);
	    (bounds[3] >= bounds[2]) || (bounds[3] += m_size2);

	    for (int i = bounds[0]; i < bounds[3]; i++) {
		const T   &data = m_fifo->internal_datum(i % m_size);
		os << "    '" << data << "'";
		if (i < bounds[1]) {
		    os << " (- Read Pending)";
		} else if (i >= bounds[2]) {
		    os << " (+ Write Pending)";
		}
		os << std::endl;
	    }
	}
	break;

      case sc_core::NCSC_CONCISE: 
	{
	    // actual # of elements and actual content is printed
	    // format is 
	    // "<slots>/<size>: <now_head>" for 1 element
	    // "<slots>/<size>: <now_head>, <now_tail>" for 2 elements
	    // "<slots>/<size>: <now_head>, <now_tail>" for 2 elements
	    // "<slots>/<size>: <now_head>, <now_tail>(+)" if tail comes from
	    // pending write
	    // "<slots>/<size>: <now_head>(+), ..., <now_tail>(+)" if head and 
	    // tail both come from pending writes

	    os << "slots:" << m_size;
	    os << ", size:" << m_fifo->internal_num_filled_slots(true);

	    if (m_fifo->internal_num_filled_slots(true) > 0) {
		// print the current head and tail
		os << ", {";

		int beg = m_fifo->internal_extended_read_index(true);
		int end = m_fifo->internal_extended_write_index(true);
		(beg <= end) || (end += m_size2);

		// print head
		os << "'" << m_fifo->internal_datum(beg % m_size) << "'";
		if (m_fifo->internal_extended_read_index(true)
		    == m_fifo->internal_extended_write_index(false)) {
		    os << "(+)";
		}

		// if >2 elems print comma followed by ...
		if (m_fifo->internal_num_filled_slots(true) > 2) {
		    os << ",...";
		}
    
		// print tail
		if (m_fifo->internal_num_filled_slots(true) > 1) {
		    os << ",'" << m_fifo->internal_datum((end - 1) % m_size) << "'";
		    
		    if (m_fifo->internal_num_pending_puts() > 0) {
			os << "(+)";
		    }
		}
		os << "}";
	    }
	    break;

	  case sc_core::NCSC_TRANSACTION:
	    {
		os << m_probe_string;
	    }
	    break;
	}
	
    }
    return true;
}

} // namespace cynw_tlm

#endif
