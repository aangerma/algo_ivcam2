#include "mex.h"
#include <algorithm>
#include <cmath>
#include "genPWRlut.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    uint32_t vertical_gain_data[] = {
     0x00003017,0x00004047,0x00004047,0x00004047
    ,0x00003047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004047,0x00004037,0x00004047
    ,0x00004047,0x00004047,0x00004047,0x00004047
    ,0x00003047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004057,0x00004047,0x00004047
    ,0x00004047,0x00005047,0x00004047,0x00004047
    ,0x00004047,0x00004057,0x00004047,0x00005047
    ,0x00004047,0x00005047,0x00004047,0x00005047
    ,0x00004047,0x00004057,0x00004047,0x00004057
    ,0x00004057,0x00005047,0x00004047,0x00004057
    ,0x00004057,0x00004057,0x00004057,0x00004057
    ,0x00004057,0x00004057,0x00004057,0x00005057
    ,0x00005047,0x00004057,0x00005057,0x00005047
    ,0x00005057,0x00005047,0x00005057,0x00005057
    ,0x00005047,0x00005057,0x00005057,0x00005057
    ,0x00005057,0x00006057,0x00005057,0x00005057
    ,0x00006057,0x00005057,0x00005067,0x00006057
    ,0x00006057,0x00006057,0x00006057,0x00006057
    ,0x00005067,0x00006067,0x00006067,0x00005067
    ,0x00006067,0x00006077,0x00006067,0x00007067
    ,0x00006067,0x00006077,0x00007077,0x00007067
    ,0x00007077,0x00007077,0x00007077,0x00007087
    ,0x00008077,0x00007087,0x00008087,0x00009087
    ,0x00008087,0x00009097,0x00009097,0x0000a097
    ,0x0000a097,0x0000a0b7,0x0000b0b7,0x0000c0b7
    ,0x0000d0c7,0x0000e0d7,0x0000f0e7,0x00012107
    ,0x00015137,0x0001c177,0x000b0253,0x0001c251
    ,0x00015171,0x00012131,0x0000f101,0x0000e0e1
    ,0x0000d0d1,0x0000c0c1,0x0000b0b1,0x0000a0b1
    ,0x0000a0b1,0x0000a091,0x00009091,0x00009091
    ,0x00008091,0x00009081,0x00008081,0x00007081
    ,0x00008081,0x00007071,0x00007081,0x00007071
    ,0x00007071,0x00007071,0x00007061,0x00006071
    ,0x00006071,0x00007061,0x00006061,0x00006061
    ,0x00006071,0x00005061,0x00006061,0x00006061
    ,0x00005061,0x00006061,0x00006051,0x00006051
    ,0x00006051,0x00006051,0x00005051,0x00005061
    ,0x00006051,0x00005051,0x00005051,0x00006051
    ,0x00005051,0x00005051,0x00005051,0x00005051
    ,0x00005051,0x00005041,0x00005051,0x00005051
    ,0x00005041,0x00005051,0x00005041,0x00004051
    ,0x00005051,0x00005041,0x00004051,0x00004051
    ,0x00004051,0x00004051,0x00004051,0x00004051
    ,0x00004051,0x00004051,0x00004051,0x00005041
    ,0x00004041,0x00004051,0x00004051,0x00004041
    ,0x00004051,0x00005041,0x00004041,0x00005041
    ,0x00004041,0x00005041,0x00004041,0x00004041
    ,0x00004051,0x00004041,0x00004041,0x00005041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004051,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00003041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004031
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00003041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004031,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004031
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00003041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004031
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00003017
    ,0x00004047,0x00004047,0x00004047,0x00004047
    ,0x00003047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004047,0x00004037,0x00004047
    ,0x00004047,0x00004047,0x00004047,0x00004047
    ,0x00003047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004047,0x00004047,0x00004047
    ,0x00004047,0x00004057,0x00004047,0x00004047
    ,0x00004047,0x00005047,0x00004047,0x00004047
    ,0x00004047,0x00004057,0x00004047,0x00005047
    ,0x00004047,0x00005047,0x00004047,0x00005047
    ,0x00004047,0x00004057,0x00004047,0x00004057
    ,0x00004057,0x00005047,0x00004047,0x00004057
    ,0x00004057,0x00004057,0x00004057,0x00004057
    ,0x00004057,0x00004057,0x00004057,0x00005057
    ,0x00005047,0x00004057,0x00005057,0x00005047
    ,0x00005057,0x00005047,0x00005057,0x00005057
    ,0x00005047,0x00005057,0x00005057,0x00005057
    ,0x00005057,0x00006057,0x00005057,0x00005057
    ,0x00006057,0x00005057,0x00005067,0x00006057
    ,0x00006057,0x00006057,0x00006057,0x00006057
    ,0x00005067,0x00006067,0x00006067,0x00005067
    ,0x00006067,0x00006077,0x00006067,0x00007067
    ,0x00006067,0x00006077,0x00007077,0x00007067
    ,0x00007077,0x00007077,0x00007077,0x00007087
    ,0x00008077,0x00007087,0x00008087,0x00009087
    ,0x00008087,0x00009097,0x00009097,0x0000a097
    ,0x0000a097,0x0000a0b7,0x0000b0b7,0x0000c0b7
    ,0x0000d0c7,0x0000e0d7,0x0000f0e7,0x00012107
    ,0x00015137,0x0001c177,0x000b0253,0x0001c251
    ,0x00015171,0x00012131,0x0000f101,0x0000e0e1
    ,0x0000d0d1,0x0000c0c1,0x0000b0b1,0x0000a0b1
    ,0x0000a0b1,0x0000a091,0x00009091,0x00009091
    ,0x00008091,0x00009081,0x00008081,0x00007081
    ,0x00008081,0x00007071,0x00007081,0x00007071
    ,0x00007071,0x00007071,0x00007061,0x00006071
    ,0x00006071,0x00007061,0x00006061,0x00006061
    ,0x00006071,0x00005061,0x00006061,0x00006061
    ,0x00005061,0x00006061,0x00006051,0x00006051
    ,0x00006051,0x00006051,0x00005051,0x00005061
    ,0x00006051,0x00005051,0x00005051,0x00006051
    ,0x00005051,0x00005051,0x00005051,0x00005051
    ,0x00005051,0x00005041,0x00005051,0x00005051
    ,0x00005041,0x00005051,0x00005041,0x00004051
    ,0x00005051,0x00005041,0x00004051,0x00004051
    ,0x00004051,0x00004051,0x00004051,0x00004051
    ,0x00004051,0x00004051,0x00004051,0x00005041
    ,0x00004041,0x00004051,0x00004051,0x00004041
    ,0x00004051,0x00005041,0x00004041,0x00005041
    ,0x00004041,0x00005041,0x00004041,0x00004041
    ,0x00004051,0x00004041,0x00004041,0x00005041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004051,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00003041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004031
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00003041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004031,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004031
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00003041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004031
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00004041
    ,0x00004041,0x00004041,0x00004041,0x00000000
    
};

uint16_t n = sizeof(vertical_gain_data) / sizeof(unsigned int);



plhs[0] = mxCreateNumericMatrix(1, 65, mxSINGLE_CLASS, mxREAL);
float* lut = reinterpret_cast<float*>(mxGetData(plhs[0]));

Params p;
p.yfov = *reinterpret_cast<float*>(mxGetData(prhs[0]));;
p.laser_BIAS = *reinterpret_cast<uint8_t*>(mxGetData(prhs[1]));
p.laser_MODULATION_REF = *reinterpret_cast<uint8_t*>(mxGetData(prhs[2]));



genPWRlut(vertical_gain_data, n,p,lut);

}