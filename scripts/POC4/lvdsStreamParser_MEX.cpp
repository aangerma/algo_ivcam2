#include "mex.h"
#include <stdint.h>
#include <vector>
#include <assert.h>


static const int SHRT_CODE_LEN = 15;
static const int LONG_CODE_LEN = 24;

struct Packet
{
    int    _ax;
    int    _ay;
    bool   _sx;
    bool   _sy;
    double _ts;
    int   _um;
    
    
    
public:
    void ax(int    v,bool inc=false) { _ax=v+(inc?_ax:0);_um=1;}
    void ay(int    v,bool inc=false) { _ay=v+(inc?_ay:0);_um=2;}
    void sx(bool   v               ) { _sx=v;_um=1;}
    void sy(bool   v               ) { _sy=v;_um=2;}
    
    void ts(double v) { _ts=v;}
    
    int    ax()const { return _ax; }
    int    ay()const { return _ay; }
    bool   sx()const { return _sx; }
    bool   sy()const { return _sy; }
    int    um()const { return _um; }
    double ts()const { return _ts; }
    
    Packet() :_ax(1<<11), _ay(0),_um(0) {}
    
    
    
    
    
};
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    uint8_t* data = static_cast<uint8_t*>(mxGetData(prhs[0]));
    double* t = mxGetPr(prhs[1]);
    size_t n = mxGetNumberOfElements(prhs[0]);
    //search for 5 sequntal zeros;
    int seqzero = 0;
    int indx = 0;
    for (; indx != n && seqzero != 5; ++indx)
    {
        seqzero = data[indx] ? 0 : seqzero + 1;
    }
    //indx is now one bit after the 5 sequntal zeros
    
    std::vector<Packet> angxy;
    
    bool firstLongPacketx=false;
    bool firstLongPackety=false;
    
    
    //inline function that typecast and bitshift by n
    auto cbs = [](uint8_t v, int n) {return int(static_cast<uint16_t>(v) << n); };
    
    while (true)
    {
        for (; indx != n && !data[indx]; ++indx);
        //indx now points on the first no-zero element
        //mexPrintf("-----%d\n", indx);
        if (indx >= n - SHRT_CODE_LEN - 1)
            break;
        
        int packetLen;
        if (data[indx + 1])//long code
        {
            uint16_t cmd
                    = cbs(data[indx + 2], 0)
                    + cbs(data[indx + 3], 1)
                    + cbs(data[indx + 5], 2);
            uint16_t val
                    = cbs(data[indx + 6], 0)
                    + cbs(data[indx + 7], 1)
                    + cbs(data[indx + 9], 2)
                    + cbs(data[indx + 10], 3)
                    + cbs(data[indx + 11], 4)
                    + cbs(data[indx + 13], 5)
                    + cbs(data[indx + 14], 6)
                    + cbs(data[indx + 15], 7)
                    + cbs(data[indx + 17], 8)
                    + cbs(data[indx + 18], 9)
                    + cbs(data[indx + 19], 10)
                    + cbs(data[indx + 21], 11);
            packetLen = LONG_CODE_LEN;
            
            Packet s = angxy.empty()? Packet():  angxy.back();
            s.ts(t[indx]);
            
            switch (cmd)
            {
                case 0:
                    s.ay(val);
                    if(!firstLongPackety & angxy.size()>3)
                    {
                        firstLongPackety=true;
                        int val2add = val-2*angxy[angxy.size()-2].ay()+angxy[angxy.size()-3].ay();
                        for(int i=0;i!=angxy.size();++i)
                            angxy[i].ay(val2add,true);
                    }
                    break;
                case 1:
                    s.ax(val);
                    if(!firstLongPacketx & angxy.size()>3)
                    {
                        firstLongPacketx=true;
                        int val2add = val-2*angxy[angxy.size()-2].ax()+angxy[angxy.size()-3].ax();
                        for(int i=0;i!=angxy.size();++i)
                            angxy[i].ax(val2add,true);
                    }
                    
                    break;
            }
            angxy.push_back(s);
            
        }
        else//short code
        {
            packetLen = SHRT_CODE_LEN;
            if (!angxy.empty() )//havent recive long mesg yet
            {
                
                uint16_t cmd
                        = cbs(data[indx + 2], 0)
                        + cbs(data[indx + 3], 1);
                int  val
                        = cbs(data[indx + 5], 0)
                        + cbs(data[indx + 6], 1)
                        + cbs(data[indx + 7], 2)
                        + cbs(data[indx + 9], 3)
                        + cbs(data[indx + 10], 4)
                        + cbs(data[indx + 11], 5);
                Packet s = angxy.back();
                
                s.ts(t[indx]);
                switch (cmd)
                {
                    case 0:				s.ay(+val,true); break;
                    case 1:				s.ay(-val,true); break;
                    case 2:				s.ax(+val,true); break;
                    case 3:				s.ax(-val,true); break;
                }
                angxy.push_back(s);
            }
            
            
        }
        
        
        //chesum
        for (int i = 4; i < packetLen; i += 4)
        {
            if (data[indx + i] == data[indx + i - 1])
            {
                mexPrintf("Bad checsum on index %d", indx + i + 1);
                mexErrMsgTxt("chesum error");
            }
            
        }
        
        
        indx += packetLen;
        
        
    }
    
    plhs[0] = mxCreateDoubleMatrix(1, angxy.size(), mxREAL);
    plhs[1] = mxCreateDoubleMatrix(1, angxy.size(), mxREAL);
    plhs[2] = mxCreateDoubleMatrix(1, angxy.size(), mxREAL);
    plhs[3] = mxCreateDoubleMatrix(1, angxy.size(), mxREAL);
    double* xout = mxGetPr(plhs[0]);
    double* yout = mxGetPr(plhs[1]);
    double* tout = mxGetPr(plhs[2]);
    double* lout = mxGetPr(plhs[3]);
    for (int i = 0; i != angxy.size(); ++i)
    {
        xout[i] = angxy[i].ax();
        yout[i] = angxy[i].ay();
        tout[i] = angxy[i].ts();
        lout[i] = angxy[i].um();
    }
    //mexPrintf("-----%d\n", indx);
    
}
