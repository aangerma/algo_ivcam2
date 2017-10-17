

  // AXI Write Address Channel Signals
  sc_out< bool >               	AWVALID;
  sc_out< sc_uint<T::LEN_W> >  	AWLEN;
  sc_out <sc_uint<T::SIZE_W> > 	AWSIZE;
  sc_out <sc_uint<T::BURST_W> >	AWBURST;
  sc_out <sc_uint<T::WID_W> >   	AWID;
  sc_out< sc_uint<T::ADDR_W> > 	AWADDR;
  sc_in< bool >                	AWREADY;
  sc_out< sc_uint<T::LOCK_W> >	AWLOCK;
  sc_out< sc_uint<T::CACHE_W> >	AWCACHE;
  sc_out< sc_uint<T::PROT_W> > 	AWPROT;

  // AXI Write Data Channel Signals
  sc_out< bool >               	WVALID;
  sc_out< sc_uint<T::WID_W> >   	WID;
  sc_out< typename T::strb_t>	WSTRB;
  sc_out< typename T::data_t>  	WDATA;
  sc_out< bool >               	WLAST;
  sc_in< bool >                	WREADY;

  // AXI Write Response Channel Signals
  sc_out< bool >               	BREADY;
  sc_in< sc_uint<T::WID_W> >     BID;
  sc_in< bool >                 BVALID;
  sc_in< sc_uint<T::BRESP_W> > 	BRESP;
