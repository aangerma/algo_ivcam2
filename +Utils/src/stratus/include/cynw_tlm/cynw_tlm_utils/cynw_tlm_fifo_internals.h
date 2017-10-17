// ****************************************************************************
// ctos_tlm_fifo_internals.h
//
// This file contains the ctos_tlm::tlm_fifo_internals_if class which is a
// common interface for observing the internal state of the ctos_tlm::tlm_fifo*
// classes.
//
// 
// ****************************************************************************
#ifndef CYNW_TLM_FIFO_INTERNALS_HEADER
#define CYNW_TLM_FIFO_INTERNALS_HEADER

#if defined STRATUS 
#pragma hls_ip_def
#endif	

namespace cynw_tlm
{

class tlm_fifo_internals_control_if: public virtual sc_interface {
  public:
    // These APIs are implemented by each of the fifos.
    virtual int		    internal_extended_read_index(bool now) const = 0;
    virtual int		    internal_extended_write_index(bool now) const = 0;
    virtual int		    internal_size() const = 0;
};

// *****************************************************************************
/// This is an interface for examing the internal state of a fifo. This is used
/// by tlm_fifo_trace<T>.
// *****************************************************************************
template<typename T>
class tlm_fifo_internals_if: public virtual tlm_fifo_internals_control_if {
  public:
    // These APIs are implemented by each of the fifos.
    virtual const T	    &internal_datum(int index) const = 0;

    int			    internal_num_pending_puts() const;
    int			    internal_num_pending_gets() const;
    int			    internal_num_available_for_putting() const;
    int			    internal_num_available_for_getting() const;
    int			    internal_num_filled_slots(bool	now) const;

    void		    internal_debug() const;
    int			    internal_used() const;
    int			    internal_used3() const;
  private:
    // These debug interfaces are not supported.
    bool		    nb_peek( T & , int n ) const { return false;}
    bool		    nb_poke( const T & , int n = 0 ) { return false;};
};

// *****************************************************************************
// This function returns the number of pending puts. These are puts that
// executed at this delta cycles, but whose data is not yet available for
// getting at this delta cycle.
// *****************************************************************************
template <typename T>
inline
int
tlm_fifo_internals_if<T>::internal_num_pending_puts() const
{
    int size2 = 2 * internal_size();
    int now = internal_extended_write_index(true);
    int prev = internal_extended_write_index(false);
    int pending = now + ((now >= prev) ? 0 : size2) - prev;
    return pending;
}

// *****************************************************************************
// This function returns the number of pending gets. These are gets that
// executed at this delta cycles, but whose slots are not yet available for
// putting in this delta cycle.
// *****************************************************************************
template <typename T>
inline
int
tlm_fifo_internals_if<T>::internal_num_pending_gets() const
{
    int size2 = 2 * internal_size();
    int now = internal_extended_read_index(true);
    int prev = internal_extended_read_index(false);
    int pending = now + ((now >= prev) ? 0 : size2) - prev;
    return pending;
}

// *****************************************************************************
// This function returns the number of filled slots now (now=true), or else
// (now=false) at the beginning of this clock cycle.
// *****************************************************************************
template <typename T>
inline
int
tlm_fifo_internals_if<T>::internal_num_filled_slots(bool now) const
{
    int size2 = 2 * internal_size();
    int ri = internal_extended_read_index(now);
    int wi = internal_extended_write_index(now);
    int num = wi + ((wi >= ri) ? 0 : size2) - ri;
    return num;
}

// *****************************************************************************
// This function returns the number of filled slots that are still available get
// getting at this delta cycle.
// *****************************************************************************
template <typename T>
inline
int
tlm_fifo_internals_if<T>::internal_num_available_for_getting() const
{
    return internal_num_filled_slots(false) - internal_num_pending_gets();
}

// *****************************************************************************
// This function returns the number of empty slots that are still available get
// putting at this delta cycle.
// *****************************************************************************
template <typename T>
inline
int
tlm_fifo_internals_if<T>::internal_num_available_for_putting() const
{
    return internal_size() - (internal_num_pending_puts() + internal_num_filled_slots(false));
}

// *****************************************************************************
// This function function implements the tlm_fifo::internal_debug() function of the
// OSCI tlm_fifo. It is not supported in the synthesized design.
// *****************************************************************************
template <typename T>
inline
void
tlm_fifo_internals_if<T>::internal_debug() const
{
    if (internal_num_filled_slots(false) == internal_num_pending_gets()) {
	std::cout << "empty" << std::endl;
    }
    if (internal_num_filled_slots(false) + internal_num_pending_puts() == internal_size()) {
	std::cout << "full" << std::endl;
    }

    std::cout << "size " << internal_size()
	      << " - " << internal_used() << " used " << std::endl;

    std::cout << "readable " 
	      << internal_num_filled_slots(false) << std::endl;

    std::cout << "written/read " 
	      << internal_num_pending_puts() << "/" << internal_num_pending_gets()
	      << std::endl;
}

// *****************************************************************************
// This is function of the debug interface returns the number of slots that
// where filled at the start of this delta cycle that have not been read out
// (during this delta cycle).
// *****************************************************************************
template <typename T>
inline
int
tlm_fifo_internals_if<T>::internal_used() const
{
    return internal_num_filled_slots(false) - internal_num_pending_gets();
}

// *****************************************************************************
// This is function of the debug interface returns the number of slots that
// where empty at the start of this delta cycle that have not been filled
// (during this delta cycle).
// *****************************************************************************
template <typename T>
inline
int
tlm_fifo_internals_if<T>::internal_used3() const
{
    return  internal_num_filled_slots(false) + internal_num_pending_puts();
}

} // namespace cynw_tlm

#endif

