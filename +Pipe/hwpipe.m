function [ pipeOut,memoryLayout ] = hwpipe( indata, regs,luts, memoryLayout, lgr,traceOutDir)

pipeOut = struct();


globalTic = tic;

lgr.print('STARTING HWPIPE\n');

assert(any(bitand(indata.flags,1)),'All ld_on flag signals are low');
assert(any(bitand(indata.flags,2)),'All tx_code_start flag signals are low');

%%
localTic=tic; lgr.print('\tComputing ASNC...');
[indata.fast,indata.slow, indata.xy, indata.flags] = Pipe.ASNC.ASNC(indata, regs,luts,traceOutDir);
lgr.print('done(%4.2fsec)\n', toc(localTic));

%% DIGG
localTic=tic; lgr.print('\tComputing DIGG...');
[indata.slow,pipeOut.xyPix, pipeOut.nest, pipeOut.roiFlag] = Pipe.DIGG.DIGG(indata, regs,luts,lgr,traceOutDir);
lgr.print('done(%4.2fsec)\n', toc(localTic));

%% RAST
localTic=tic; lgr.print('\tComputing RAST...');
%xyT = 64/regs.gnr.sampleRate;
[pipeOut.cma,pipeOut.iImgRAW,pipeOut.aImg,pipeOut.dutyCycle, pipeOut.pipeFlags,pipeOut.pixIndOutOrder, pipeOut.pixRastOutTime ] =...
    Pipe.RAST.RAST(indata, pipeOut, regs, luts, lgr,traceOutDir);
lgr.print('done(%4.2fsec)\n', toc(localTic));

%% DCOR
localTic=tic; lgr.print('\tComputing DCOR...');
[pipeOut.corrOffset, pipeOut.corr,pipeOut.psnr,pipeOut.iImgRAW,pipeOut.tiImg] = Pipe.DCOR.DCOR(pipeOut,regs,luts,lgr,traceOutDir);
lgr.print('done(%4.2fsec)\n', toc(localTic));

%% DEST
localTic=tic; lgr.print('\tComputing DEST...');
[pipeOut.zImgRAW, pipeOut.cImgRAW,pipeOut.rtdImg,pipeOut.iImgRAW,pipeOut.max_val] = Pipe.DEST.DEST(pipeOut,regs,luts, lgr,traceOutDir);
lgr.print('done(%4.2fsec)\n', toc(localTic));

%% CBUF
localTic=tic; lgr.print('\tComputing CBUF...');
[pipeOut.zImgRAW, pipeOut.cImgRAW, pipeOut.iImgRAW] = Pipe.CBUF.CBUF(pipeOut,regs,luts,lgr,traceOutDir);
lgr.print('done(%4.2fsec)\n', toc(localTic));

%% JFIL
localTic=tic; lgr.print('\tComputing JFIL...');
[pipeOut.zImg,pipeOut.iImg, pipeOut.cImg,pipeOut.nnfeatures,pipeOut.dNNOutput,pipeOut.iNNOutput,pipeOut.BTStages] = Pipe.JFIL.JFIL(pipeOut,regs,luts,lgr,traceOutDir);
lgr.print('done(%4.2fsec)\n', toc(localTic));

%% STAT
localTic=tic; lgr.print('\tComputing STAT...');
memoryLayout = Pipe.STAT.STAT(pipeOut,memoryLayout,regs,luts,traceOutDir);
lgr.print('done(%4.2fsec)\n', toc(localTic));

%% PCKR
localTic=tic; lgr.print('\tComputing PCKR...');
[pipeOut.stream{1},pipeOut.stream{2}, pipeOut.stream{3}] = Pipe.PCKR.PCKR(pipeOut,regs,luts,traceOutDir);
lgr.print('done(%4.2fsec)\n', toc(localTic));


%%
pipeOut.timeEval = toc(globalTic);
lgr.print('HWPipe finished in %4.2f sec\n', pipeOut.timeEval);


%% x,y,z,r calculation (not part of ASIC)
[pipeOut.vImg,pipeOut.rImg] = genVerts(pipeOut.zImg,regs);




end





function [v,r]=genVerts(zUINT16,regs)


[sinx,cosx,~,~,sinw,cosw,~]=Pipe.DEST.getTrigo(size(zUINT16),regs);
 
    


% [nyi,nxi]=ndgrid((1:h)/h*2-1,(1:w)/w*2-1);
% 
% phi   = atand(tand(regs.FRMW.xfov/2).*nxi);
% theta = atand(tand(regs.FRMW.yfov/2).*nyi);
z = double(zUINT16)/bitshift(1,regs.GNRL.zMaxSubMMExp);
z(zUINT16==0)=nan;

r = z./(cosx.*cosw);
x = z.*sinx./cosx;
y = z.*sinw./(cosw.*cosx);

v = cat(3,x,y,z);
end


