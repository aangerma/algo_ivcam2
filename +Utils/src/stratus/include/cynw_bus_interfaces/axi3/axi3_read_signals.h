

  sc_signal< bool >                     	ARVALID; 
  sc_signal< sc_uint<axitraits ::LEN_W> >    ARLEN; 
  sc_signal <sc_uint<axitraits ::SIZE_W> >   ARSIZE; 
  sc_signal <sc_uint<axitraits ::BURST_W> >  ARBURST; 
  sc_signal <sc_uint<axitraits ::RID_W> >    	ARID; 
  sc_signal< sc_uint<axitraits ::ADDR_W> > 	ARADDR; 
  sc_signal< bool >                     	ARREADY; 
  sc_signal< sc_uint<axitraits ::LOCK_W> >   ARLOCK; 
  sc_signal< sc_uint<axitraits ::CACHE_W> >  ARCACHE;   
  sc_signal< sc_uint<axitraits ::PROT_W> >   ARPROT; 
  sc_signal< bool >                     	RREADY; 
  sc_signal< bool >                     	RVALID; 
  sc_signal< sc_uint<axitraits::RID_W> >    	RID; 
  sc_signal< typename axitraits ::data_t>  		RDATA; 
  sc_signal< sc_uint<axitraits ::BRESP_W> >  RRESP; 
  sc_signal< bool >                     	RLAST;
