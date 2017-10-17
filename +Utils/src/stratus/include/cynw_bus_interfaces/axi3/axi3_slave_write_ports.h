

  // AXI Write Address Channel Signals
  sc_in< bool >                 AWVALID;
  sc_in< sc_uint<T::LEN_W> >    AWLEN;
  sc_in <sc_uint<T::SIZE_W> >   AWSIZE;
  sc_in <sc_uint<T::BURST_W> >  AWBURST;
  sc_in <sc_uint<T::WID_W> >     AWID;
  sc_in< sc_uint<T::ADDR_W> >   AWADDR;
  sc_out< bool >                AWREADY;
  sc_in< sc_uint<T::LOCK_W> >   AWLOCK;
  sc_in< sc_uint<T::CACHE_W> >  AWCACHE;
  sc_in< sc_uint<T::PROT_W> >   AWPROT;

  // AXI Write Data Channel Signals
  sc_in< bool >                 WVALID;
  sc_in< sc_uint<T::WID_W> >     WID;
  sc_in< typename T::strb_t>    WSTRB;
  sc_in< typename T::data_t>    WDATA;
  sc_in< bool >                 WLAST;
  sc_out< bool >                WREADY;
  
  // AXI Write Response Channel Signals
  sc_in< bool >                 BREADY;
  sc_out< sc_uint<T::WID_W> >    BID;
  sc_out< bool >                BVALID;
  sc_out< sc_uint<T::BRESP_W> > BRESP;
  

