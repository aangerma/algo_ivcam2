


  sc_signal< bool >                     	AWVALID; 
  sc_signal< sc_uint<axitraits ::LEN_W> >    AWLEN; 
  sc_signal <sc_uint<axitraits ::SIZE_W> >   AWSIZE; 
  sc_signal <sc_uint<axitraits ::BURST_W> >  AWBURST; 
  sc_signal <sc_uint<axitraits ::WID_W> >    	AWID; 
  sc_signal< sc_uint<axitraits ::ADDR_W> >  	AWADDR; 
  sc_signal< bool >                     	AWREADY; 
  sc_signal< sc_uint<axitraits ::LOCK_W> >   AWLOCK; 
  sc_signal< sc_uint<axitraits ::CACHE_W> >  AWCACHE;   
  sc_signal< sc_uint<axitraits ::PROT_W> >   AWPROT; 
  sc_signal< bool >                      	WVALID; 
  sc_signal< sc_uint<axitraits ::WID_W> >     WID; 
  sc_signal< typename axitraits ::strb_t> 		WSTRB; 
  sc_signal< typename axitraits ::data_t>   		WDATA; 
  sc_signal< bool >                      	WLAST; 
  sc_signal< bool >                      	WREADY; 
  sc_signal< bool >                     	BREADY; 
  sc_signal< sc_uint<axitraits ::WID_W> >    	BID; 
  sc_signal< bool >                     	BVALID; 
  sc_signal< sc_uint<axitraits ::BRESP_W> >  BRESP; 
