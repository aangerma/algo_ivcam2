function [xyQout,roi_flag]=GENG(xyQ,scan_dir,regs,luts,lgr,traceOutDir)


lgr.print2file('\t\t------- GENG -------\n');


angxQ = xyQ(1,:);
angyQ = xyQ(2,:);
if(regs.MTLB.xyRasterInput)
    xyQout = xyQ;
    roi_flag = true(1,size(xyQout,2));
    roi_flag([1 end])=false;
    return;
elseif(regs.DIGG.sphericalEn)
    xx = int32(angxQ);
    yy = int32(angyQ);
    
    xx = xx*int32(regs.DIGG.sphericalScale(1));
    yy = yy*int32(regs.DIGG.sphericalScale(2));
    
    xx = bitshift(xx,-12+2);
    yy = bitshift(yy,-12);
    
    xx = xx+int32(regs.DIGG.sphericalOffset(1));
    yy = yy+int32(regs.DIGG.sphericalOffset(2));
    
    xx = max(-2^14,min(2^14-1,xx));%15bit signed data
    yy = max(-2^11,min(2^11-1,yy));%12bit signed data
    
    xyQout=int16([xx;yy]);
elseif(regs.GNRL.rangeFinder)
    
    yy=angyQ;%#ok
    %use 2LSB of X and 4 LSB of Y to access 64 entries LUT
    index = bitshift(bitand(angxQ,3),4)+bitand(angyQ,15);  %[0-63] index = {x[1:0] y[3:0]}
    int4LUT = int16(bitshift(typecast(bitshift(regs.DIGG.gengRangeFinderLUT,4),'int8'),-4));
    xx=map(int4LUT,1+min(63,max(0,index)));
    xx= bitshift(xx,2);
    yy= zeros(size(xx),'int16');
    xyQout=[xx;yy];
    if(regs.MTLB.debug)
        %%
        figure(34875)
        subplot(411)
        plot(angxQ);        title('input X')
        subplot(412)
        plot(angyQ);        title('input Y')
        subplot(413)
        plot(xx);        title('output X')
        subplot(414)
        plot(yy);        title('output Y')
    end
else
    
    
    
    
    
    %% ang2xy
    [x_,y_] = Pipe.DIGG.ang2xy(angxQ,angyQ,regs,lgr,traceOutDir);
    
    
%     lgr.print2file(sprintf('\t\tx (ang2xy output) = %s\n\t\ty (ang2xy output) = %s\n',  dec2hexFast(x(1),4),dec2hexFast(y(1),4)));
    
    
    
    %% undist
    [x,y] = Pipe.DIGG.undist(x_,y_,regs,luts,lgr,traceOutDir);
    
%     lgr.print2file(sprintf('\t\tx (undist output) = %s\n\t\ty (undist output) = %s\n',         dec2hexFast(x(1),4),dec2hexFast(y(1),4)));
    
    
    %% ranger
    xyQout = Pipe.DIGG.ranger(x, y, regs);
end
% lgr.print2file(sprintf('\t\txyQout ((x, y) ranger output) = %s, %s\n',   dec2hexFast(xyQout(1,1),4),dec2hexFast(xyQout(2,1),4)));

%% roi
roi_flag = Pipe.DIGG.roiFlag(xyQout, angyQ, regs);

inRoiMask = xyQout(1,:)/4>0 & xyQout(1,:)/4<=regs.GNRL.imgHsize & xyQout(2,:)>0 & xyQout(2,:)<=regs.GNRL.imgVsize;
lgr.print2file(sprintf('coverege: samples in ROI %.2f%%',sum(inRoiMask)/size(xyQout,2)*100));

lgr.print2file(sprintf('\t\troi_beg/end indices = %d/%d\n',find(roi_flag,1),find(roi_flag,1,'last')));
%%
locs=find(gradient(double(xyQout(2,:)))>0 & scan_dir==0 | gradient(double(xyQout(2,:)))<0 & scan_dir==1);
if(regs.MTLB.debug)
    %%
    n=1:size(xyQout,2);
    figure(23432)
    subplot(211)
    plot(n,xyQout(2,:),n,double(scan_dir)*double(max(xyQout(2,:))))
    
    subplot(212)
    plot(n,xyQout(2,:),locs,xyQout(2,locs),'ro')
end

if(length(locs)/size(xyQout,2)>0.1)
    warning('DIGG: Y scan is not monotonic in %d%% of the scans',round(length(locs)/size(xyQout,2)*100));
end


xyQout = Pipe.DIGG.monotonicY(xyQout, scan_dir);


    lgr.print2file('\t\t----- end GENG -----\n');


end



