  public:
    virtual bool	    ncsc_supports_deposit() const
				{ return m_trace.ncsc_supports_deposit();}
    virtual sc_event	    *ncsc_probe_event()
				{return m_trace.ncsc_probe_event();}
    virtual bool	    ncsc_print_value(::std::ostream &os, ncsc_value_mode_t mode) const
				{return m_trace.ncsc_print_value(os, mode);}
    virtual bool	    ncsc_deposit_value(const char *s, bool force) 
				{return ncsc_deposit_value(s,force);}
    virtual const char	    *ncsc_print() const
				{ return m_trace.ncsc_print(); }
    virtual bool	    ncsc_needs_sequence_probe() const
				{ return m_trace.ncsc_needs_sequence_probe();}
    virtual bool	    ncsc_is_transaction_probe() const
				{ return m_trace.ncsc_is_transaction_probe();}
    virtual void	    ncsc_write_transaction(sc_txp *txp)
				{ return m_trace.ncsc_write_transaction(txp);}
    virtual bool	    ncsc_supports_value() const
				{ return m_trace.ncsc_supports_value();}
    virtual bool	    ncsc_supports_force() const
				{ return m_trace.ncsc_supports_force();}
    virtual bool	    ncsc_supports_value_change_callback() const
				{ return m_trace.ncsc_supports_value_change_callback();}
