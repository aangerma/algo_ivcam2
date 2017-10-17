
#define HLS_CAT_CTOR(nm1, nm2)  nm2( HLS_CAT_NAMES(nm1, #nm2 ) )

#define AXI3_WRITE_PORTS_CTOR(name) \
    HLS_CAT_CTOR(name, AWVALID), \
    HLS_CAT_CTOR(name, AWLEN), \
    HLS_CAT_CTOR(name, AWSIZE), \
    HLS_CAT_CTOR(name, AWBURST), \
    HLS_CAT_CTOR(name, AWID), \
    HLS_CAT_CTOR(name, AWADDR), \
    HLS_CAT_CTOR(name, AWREADY), \
    HLS_CAT_CTOR(name, AWLOCK), \
    HLS_CAT_CTOR(name, AWCACHE), \
    HLS_CAT_CTOR(name, AWPROT), \
    HLS_CAT_CTOR(name, WVALID), \
    HLS_CAT_CTOR(name, WID), \
    HLS_CAT_CTOR(name, WSTRB), \
    HLS_CAT_CTOR(name, WDATA), \
    HLS_CAT_CTOR(name, WLAST), \
    HLS_CAT_CTOR(name, WREADY), \
    HLS_CAT_CTOR(name, BREADY), \
    HLS_CAT_CTOR(name, BID), \
    HLS_CAT_CTOR(name, BVALID), \
    HLS_CAT_CTOR(name, BRESP) \

    
