#define HLS_CAT_CTOR(nm1, nm2)  nm2( HLS_CAT_NAMES(nm1, #nm2 ) )

#define AXI3_READ_PORTS_CTOR(name) \
    HLS_CAT_CTOR(name, ARVALID), \
    HLS_CAT_CTOR(name, ARLEN), \
    HLS_CAT_CTOR(name, ARSIZE), \
    HLS_CAT_CTOR(name, ARBURST), \
    HLS_CAT_CTOR(name, ARID), \
    HLS_CAT_CTOR(name, ARADDR), \
    HLS_CAT_CTOR(name, ARREADY), \
    HLS_CAT_CTOR(name, ARLOCK), \
    HLS_CAT_CTOR(name, ARCACHE), \
    HLS_CAT_CTOR(name, ARPROT), \
    HLS_CAT_CTOR(name, RREADY), \
    HLS_CAT_CTOR(name, RVALID), \
    HLS_CAT_CTOR(name, RID), \
    HLS_CAT_CTOR(name, RDATA), \
    HLS_CAT_CTOR(name, RRESP), \
    HLS_CAT_CTOR(name, RLAST)
