function compile_fp32(debug)
if(~exist('debug','var'))
    debug=false;
end
if(debug)
    dbgf='-g';
else
    dbgf='';
end
srcFiles =dirRecursive([fileparts(pwd) filesep  'src' filesep 'systemc'],'*.cpp');
incFldrs = {'','systemc',['stratus' filesep 'include']};
incFldrs = strcat('-I',fileparts(pwd),filesep,'src',filesep,incFldrs);
if(isunix)
      mex('fp32.cpp',dbgf,'-outdir',fileparts(pwd),incFldrs{:},srcFiles{:},'-silent','-largeArrayDims','CXXFLAGS="$CXXFLAGS -DSC_INCLUDE_FX -DSC_USE_PTHREADS"');
else
     mex('fp32.cpp',dbgf,'-outdir',fileparts(pwd),incFldrs{:},srcFiles{:},'-silent','COMPFLAGS="$COMPFLAGS /DSC_INCLUDE_FX"');
end
