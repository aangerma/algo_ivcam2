
#include <yvals.h>
#if (_MSC_VER >= 1600)
#define __STDC_UTF_16__
#endif
//

#include <vector>
#include "mex.h"
#include <src/ImgVectorizer.h>
#include <vector>
#include <utility>
//#include <../3rdParty/opencv/include/opencvExt/Accessor2D.h>


   typedef std::pair<double,double> Pt;
   typedef std::vector<Pt> Pgon;
   typedef std::vector<Pgon> Pgons;



template<class T>
void imgVectorizerWrapper(const void* data,size_t rows, size_t cols, double thr,Pgons* pgonsP,Pgons* plinsP)
{
	ImgVectorizer0x iv;
	iv.set0value(float(thr));
	iv.img2curves(Img<T>(cols,rows,const_cast<void*>(data)),plinsP,pgonsP);
}


mxArray* mxArrayFrompgons(const Pgons& pgons)
{
	mxArray* arr;
		arr = mxCreateCellMatrix( pgons.size(), 1 );   
	for( int i=0; i!=pgons.size(); ++i )
    {    int sz = int(pgons[i].size());
         mxArray* ptr = mxCreateDoubleMatrix(sz,2, mxREAL );        
		 double* data = mxGetPr(ptr);
		 for(int j=0;j!=sz;++j)
		 {
			 data[j+sz]=pgons[i][j].first;
			 data[j]=pgons[i][j].second;
		 }
         mxSetCell( arr, i, ptr );		               
 		 //mxDestroyArray( ptr);
     }    
	return arr;
}
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{


    if(nrhs!=2)
		mexErrMsgTxt("Usage: [pgons,plins]=imVectorize(img,thr)");
	if(!mxIsNumeric(prhs[0]))
		mexErrMsgTxt("img must be numeric");
	if(!mxIsDouble(prhs[1]))
		mexErrMsgTxt("thr must be double scalar");

	size_t rows = mxGetM(prhs[0]);
	size_t cols = mxGetN(prhs[0]);
	if(rows<=1 || cols <=1)
		mexErrMsgTxt("Image too small");

	double thr = *mxGetPr(prhs[1]);

	const void* data = mxGetData(prhs[0]);

	Pgons pgons,plins;

	if(mxIsSingle(prhs[0]))
		imgVectorizerWrapper<float>(data,rows,cols,thr,&pgons,&plins);
	else if(mxIsUint8(prhs[0]))
		imgVectorizerWrapper<unsigned char>(data,rows,cols,thr,&pgons,&plins);
	else if(mxIsUint16(prhs[0]))
		imgVectorizerWrapper<unsigned short>(data,rows,cols,thr,&pgons,&plins);
	else
		mexErrMsgTxt("Unsupported image data type");
	
	if(nrhs<1)
		return;

	plhs[0]=mxArrayFrompgons(pgons);

	if(nrhs<2)
		return;
	plhs[1]=mxArrayFrompgons(plins);



}

