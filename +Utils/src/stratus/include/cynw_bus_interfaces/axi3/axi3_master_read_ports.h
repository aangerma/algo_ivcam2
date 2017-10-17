


  // AXI Read Address Channel Signals
  sc_out< bool >               	ARVALID;
  sc_out< sc_uint<T::LEN_W> >  	ARLEN;
  sc_out <sc_uint<T::SIZE_W> > 	ARSIZE;
  sc_out <sc_uint<T::BURST_W> >	ARBURST;
  sc_out <sc_uint<T::RID_W> >   	ARID;
  sc_out< sc_uint<T::ADDR_W> >  ARADDR;
  sc_in< bool >                	ARREADY;
  sc_out< sc_uint<T::LOCK_W> > 	ARLOCK;
  sc_out< sc_uint<T::CACHE_W> >	ARCACHE;
  sc_out< sc_uint<T::PROT_W> >  ARPROT;

  // AXI Read Data Channel Signals
  sc_out< bool >               	RREADY;
  sc_in< bool >                	RVALID;
  sc_in< sc_uint<T::RID_W> >    	RID;
  sc_in< typename T::data_t>    RDATA;
  sc_in< sc_uint<T::BRESP_W> > 	RRESP;
  sc_in< bool >                	RLAST; 
