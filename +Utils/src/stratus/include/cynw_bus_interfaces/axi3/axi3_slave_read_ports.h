


  // AXI Read Address Channel Signals
  sc_in< bool >                 ARVALID;
  sc_in< sc_uint<T::LEN_W> >    ARLEN;
  sc_in <sc_uint<T::SIZE_W> >   ARSIZE;
  sc_in <sc_uint<T::BURST_W> >  ARBURST;
  sc_in <sc_uint<T::RID_W> >     ARID;
  sc_in< sc_uint<T::ADDR_W> >   ARADDR;
  sc_out< bool >                ARREADY;
  sc_in< sc_uint<T::LOCK_W> >   ARLOCK;
  sc_in< sc_uint<T::CACHE_W> >  ARCACHE;
  sc_in< sc_uint<T::PROT_W> >   ARPROT;
  
  // AXI Read Data Channel Signals
  sc_in< bool >                 RREADY;
  sc_out< bool >                RVALID;
  sc_out< sc_uint<T::RID_W> >    RID;
  sc_out< typename T::data_t >  RDATA;
  sc_out< sc_uint<T::BRESP_W> > RRESP;
  sc_out< bool >                RLAST;

