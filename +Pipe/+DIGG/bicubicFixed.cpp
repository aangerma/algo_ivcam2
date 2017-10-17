#include <mex.h>
#include <stdint.h>
#include <inttypes.h>
#include <math.h>
#include <algorithm>
#include "matrix.h"
#include "../mex/auGeneral.h"
        
using namespace std;

#define NUM_NEIGHBORS 4

//#define DEBUG


inline	int numel(const mxArray* arr)
{
    return int(mxGetN(arr))*int(mxGetM(arr));
}


uint16_t get_ind(int64_t raw_ind, uint16_t max_size, uint8_t shift, int neighbor_place)
{
    //  min(max(floor(raw_ind)-NUM_NEIGHBORS/2+1+j,0), max_size - 1)
    
    //floor and get original number (not bitshifted)
    uint16_t ind = (uint16_t)(raw_ind >> shift);
    //check max (problem because it uint and we can have minus this way)
    if (ind + 1 + neighbor_place < NUM_NEIGHBORS / 2)
    {
        ind = 0;
    }
    else
    {
        ind = ind + 1 + neighbor_place-NUM_NEIGHBORS / 2;
    }
    //check min
    if (ind>max_size-1 )
    {
        ind = max_size-1;
    }
    return ind;
}


int64_t my_floor(int64_t x, uint8_t shift)
{
    int64_t res = (int64_t)((x>>shift)<<shift);
 /*   
#ifdef DEBUG
    mexPrintf("my_floor  x original=%" PRId64 " x_floor=%" PRId64 "\n",x,res);
#endif
  */
    return res;
}










int64_t cubicInterpolate (int64_t* p, int64_t x, uint8_t shift)
{
    int64_t a0 = ((int64_t)(x*(3.0*(p[1] - p[2]) + p[3] - p[0])))>>shift;
    int64_t a1 = ((int64_t)(x*(2.0*p[0] - 5.0*p[1] + 4.0*p[2] - p[3] +a0)))>>shift;
    int64_t a2 = ((int64_t)(x*(p[2] - p[0] + a1)))>>(shift+1);
    int64_t res = p[1] + a2;
    /*
#ifdef DEBUG
    if (DEBUG) mexPrintf("result is %" PRId64 "\n\n\n\n",res);
#endif
     **/
    return res;
}


int64_t bicubicInterpolate (Image<int64_t>& neighbors, int64_t x, int64_t y, uint8_t shift)
{
    
    int64_t arr[4];
    arr[0] = cubicInterpolate(neighbors.row(0), y-my_floor(y,shift), shift);
    arr[1] = cubicInterpolate(neighbors.row(1), y-my_floor(y,shift), shift);
    arr[2] = cubicInterpolate(neighbors.row(2), y-my_floor(y,shift), shift);
    arr[3] = cubicInterpolate(neighbors.row(3), y-my_floor(y,shift), shift);
    int64_t ret = cubicInterpolate(arr, x-my_floor(x,shift), shift);
/*
#ifdef DEBUG
    if (DEBUG) mexPrintf("!!!!!!bicubicInterpolate of x=%" PRId64 " y=%" PRId64 " is %" PRId64 "  \n\n\n\n",x,y,ret);
#endif
 **/
    
    return ret;
    
}








void get_neighbors_by_ind(Image<int64_t>& LUT, uint16_t LUT_col_sz, uint16_t LUT_row_sz, int64_t x, int64_t y, uint8_t shift, Image<int64_t>& neighborsOut
        , Image<uint16_t>& neighbor_index_colOut, Image<uint16_t>& neighbor_index_rowOut)
{
    /*
    if( x >= (((int64_t)LUT_col_sz)<<shift) || y >= (((int64_t)LUT_row_sz)<<shift) || x < 0 || y < 0 )
    {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "x OR y index out of LUT bound");
    }
     **/
    x = std::max(x,int64_t(0));
    y = std::max(y,int64_t(0));
    x = std::min(x,((int64_t)LUT_col_sz)<<shift);
    y = std::min(y,((int64_t)LUT_row_sz)<<shift);
    
    //fill nieghbors:  if on edge - pad it like the edge itself
    for(int i = 0; i < NUM_NEIGHBORS; i++)
    {
        for(int j = 0; j < NUM_NEIGHBORS; j++)
        {
            neighbor_index_colOut(i, j) = get_ind(x, LUT_col_sz, shift, j);
            
            neighbor_index_rowOut(i, j) = get_ind(y, LUT_row_sz, shift, i);
            
            neighborsOut(i, j) = LUT(neighbor_index_rowOut(i, j), neighbor_index_colOut(i, j));
            
        }
    }
    
    //for validation:
            //mexPrintf("neighbor_index_rowOut(0,0)= %d neighbor_index_colOut(0,0)= %d\n",(int)neighbor_index_rowOut(0,0),(int)neighbor_index_colOut(0,0));
           // mexPrintf("neighbor_index_rowOut(3,0)= %d (3,1)= %d (3,2)= %d (3,3)= %d\n",(int)neighbor_index_rowOut(3,0),(int)neighbor_index_rowOut(3,1),(int)neighbor_index_rowOut(3,2),(int)neighbor_index_rowOut(3,3));
            //mexPrintf("neighbor_index_rowOut(13)= %d (14)= %d (15)= %d (16)= %d\n",(int)neighbor_index_rowOut[12],(int)neighbor_index_rowOut[13],(int)neighbor_index_rowOut[14],(int)neighbor_index_rowOut[15]);

   // uint16_t col_ind1 = get_ind(x, LUT_col_sz, shift, 1);
    //uint16_t row_ind1 = get_ind(y, LUT_row_sz, shift, 1);
   // return std::make_pair(row_ind1, col_ind1);

}







void mexFunction(int nlhs,  mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
    // ============= prhs (input): ==============
    //1. LUT
    //2. qx
    //3. qy
    //4. bitshift
    
    //*******input validation********
    if(nrhs != 4) {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "4 inputs required.");
    }
    if(nlhs > 3) {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "max 3 outputs required.");
    }
    
    //******LUT******
    if( !mxIsInt64(prhs[0]))
    {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "Input 1 - 'LUT' must be int64.");
    }
    uint16_t LUT_row_sz = (uint16_t)mxGetM(prhs[0]);
    uint16_t LUT_col_sz = (uint16_t)mxGetN(prhs[0]);
    
    //build LUT
    Image<int64_t> LUT((int64_t*)mxGetData(prhs[0]), LUT_row_sz, LUT_col_sz);
    // fill LUT
    for (int row=0; row < LUT_row_sz; row++)
    {
        for (int col=0; col < LUT_col_sz; col++)
        {
            LUT(row, col) = (int64_t) ((int64_t*)mxGetData(prhs[0]))[row+col*LUT_row_sz];
            /*
#ifdef DEBUG
            if (DEBUG) mexPrintf("%.2f  ",LUT(row, col));
#endif
             */
        }
        /*
#ifdef DEBUG
        
        if (DEBUG) mexPrintf("\n");
#endif
         */
    }
    
    //******qx & qy*******
    if( !mxIsInt64(prhs[1]) || !mxIsInt64(prhs[2]))
    {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "Input 2,3 - 'qx' OR 'qy' must be int64.");
    }
    int64_t* qx = (int64_t*)mxGetData(prhs[1]);
    int nx = numel(prhs[1]);
    int64_t* qy = (int64_t*)mxGetData(prhs[2]);
    int ny = numel(prhs[2]);
    if(nx != ny)
    {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "size(qx) ~= size(qy).");
    }
    
    //******bitshift*******
    if( !mxIsUint8(prhs[3]) )
    {
        mexErrMsgIdAndTxt("MyProg:ConvertString",
                "Input 4 - 'bitshift'  must be uint8.");
    }
    uint8_t* shift_ = (uint8_t*)mxGetData(prhs[3]);
    uint8_t shift =  *shift_;
    
    //============== plhs (output): =============
    plhs[0]=mxCreateNumericMatrix(nx,1,mxINT64_CLASS,mxREAL);
    int64_t* qv = (int64_t*)mxGetData(plhs[0]);
    
    const int nn = NUM_NEIGHBORS*NUM_NEIGHBORS;
    plhs[1]=mxCreateNumericMatrix(nx,nn,mxUINT16_CLASS,mxREAL);
    uint16_t* qneighbor_index_col = (uint16_t*)mxGetData(plhs[1]);
    
    plhs[2]=mxCreateNumericMatrix(nx,nn,mxUINT16_CLASS,mxREAL);
    uint16_t* qneighbor_index_row = (uint16_t*)mxGetData(plhs[2]);
    
    //============== build nieghbors matrix ==============
    Image<int64_t> neighbors(NUM_NEIGHBORS, NUM_NEIGHBORS);
    Image<uint16_t> neighbor_index_row(NUM_NEIGHBORS, NUM_NEIGHBORS);
    Image<uint16_t> neighbor_index_col(NUM_NEIGHBORS, NUM_NEIGHBORS);

   
    //============== calc =======================
    for(int i=0; i!=nx; ++i)
    {        
        get_neighbors_by_ind(LUT, LUT_col_sz, LUT_row_sz, qx[i], qy[i], shift,neighbors,
                neighbor_index_col,neighbor_index_row) ;
        
        /*
#ifdef DEBUG
        {
            mexPrintf("i=%d : qx[i]=%" PRId64 " qy[i]=%" PRId64 "\n",i,qx[i],qy[i]);
            mexPrintf("neighbors of x=%" PRId64 " y=%" PRId64 "\n",qx[i],qy[i]);
            for(int i = 0; i < NUM_NEIGHBORS; i++)
            {
                for(int j = 0; j < NUM_NEIGHBORS; j++)
                {
                    mexPrintf("%" PRId64 "  ",neighbors(i, j));
                }
                mexPrintf("\n");
            }
        }
#endif
         **/
        
        qv[i] = bicubicInterpolate(neighbors, qx[i], qy[i],shift);
        //uint16_t c = neighbor_index_col[0];
        for (int j=0;j<NUM_NEIGHBORS;j++){
            for (int k=0;k<NUM_NEIGHBORS;k++){
        qneighbor_index_col[nn*i+j*NUM_NEIGHBORS+k] = neighbor_index_col(j,k);
        qneighbor_index_row[nn*i+j*NUM_NEIGHBORS+k] = neighbor_index_row(j,k);
        }
        }

        //qneighbor_index11[2*i+1] = p.second;
        //if(i<10)
           // mexPrintf("neighbor_index11[2*i]= %d neighbor_index11[2*i+1]= %d\n",(int)neighbor_index11[2*i],(int)neighbor_index11[2*i+1]);
 
		//std::copy(neighbors.row(0), neighbors.row(0)+nn, qneighbors + i*nn);
		
    }

}






