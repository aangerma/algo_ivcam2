function [ xnew,ynew ] = undist( xold,yold,regs,luts,lgr,traceOutDir )

% lgr.print2file('\t\t\t------- undist -------\n');

% lgrIndx = iff(regs.MTLB.loggerChunkIndex<length(xold),regs.MTLB.loggerChunkIndex+1,[]);

if(regs.DIGG.undistBypass)
    xnew = xold;
    ynew = yold;
else
    %%
    
%     lgr.print2file('\t\tx,y in: %s,%s\n',dec2hexFast(xold(lgrIndx),8),dec2hexFast(yold(lgrIndx),8));
    
    %x/y - 12/11+15
    shift = double(regs.DIGG.bitshift);
    % shift + scale in
    xx = int32(bitshift(int64(xold).*int64(regs.DIGG.xScaleIn),-shift)) + regs.DIGG.xShiftIn;
    yy = int32(bitshift(int64(yold).*int64(regs.DIGG.yScaleIn),-shift)) + regs.DIGG.yShiftIn;
    
%     lgr.print2file('\t\tx,y scale+shift: %s,%s\n',dec2hexFast(xx(lgrIndx),8),dec2hexFast(yy(lgrIndx),8));
    
    
    % undist
    xylut = typecast(luts.DIGG.lensModel,'int32');
    xLUT = reshape(xylut(1:2:end),32,32);
    yLUT = reshape(xylut(2:2:end),32,32);
    
    
    [xnew,x_xaddr,x_yaddr,xnei,xindRow,xIndCol]= bicubicInterp(xLUT,regs.DIGG,xx,yy);%#ok
    [ynew,y_xaddr,y_yaddr,ynei,yindRow,yIndCol]= bicubicInterp(yLUT,regs.DIGG,xx,yy);%#ok
    
%     lgr.print2file('\t\tx,y interp: %s,%s\n',dec2hexFast(xnew(lgrIndx),8),dec2hexFast(ynew(lgrIndx),8));
%     lgr.print2file('\t\tx  v/h addr: %s,%s\n',dec2hexFast(x_xaddr(lgrIndx),8),dec2hexFast(x_yaddr(lgrIndx),8));
%     lgr.print2file('\t\tx  neighbors: %s\n',vec(strcat(dec2hexFast(xnei(lgrIndx,:),8),'_')')');
%     lgr.print2file('\t\ty  v/h addr: %s,%s\n',dec2hexFast(y_xaddr(lgrIndx),8),dec2hexFast(y_yaddr(lgrIndx),8));
%     lgr.print2file('\t\ty  neighbors: %s\n',vec(strcat(dec2hexFast(ynei(lgrIndx,:),8),'_')')');
%     lgr.print2file('\t\txLUT index of neighbors: %s\n', vec(strcat('(' ,dec2hexFast(xindRow(:,lgrIndx)) ,',', dec2hexFast(xIndCol(:,lgrIndx)) ,')')')'  );
%     lgr.print2file('\t\tyLUT index of neighbors: %s\n', vec(strcat('(' ,dec2hexFast(yindRow(:,lgrIndx)) ,',', dec2hexFast(yIndCol(:,lgrIndx)) ,')')')'  );

    % shift + scale out
    xnew = int32(bitshift(int64(xnew).*int64(regs.DIGG.xScaleOut),-shift)) + regs.DIGG.xShiftOut;
    ynew = int32(bitshift(int64(ynew).*int64(regs.DIGG.yScaleOut),-shift)) + regs.DIGG.yShiftOut;
    
%     lgr.print2file('\t\tx,y out: %s,%s\n',dec2hexFast(xnew(lgrIndx),8),dec2hexFast(ynew(lgrIndx),8));
    
end
if(~isempty(traceOutDir) )
    
    Utils.buildTracer([dec2hexFast(ynew,8) dec2hexFast(xnew,8)],'DIGG_undist_out',traceOutDir);
    
    %% undist LUT trace
    s=1:4:32;
    lutX=reshape(luts.DIGG.xLensModel,32,32);
    lutY=reshape(luts.DIGG.yLensModel,32,32);
    lutxy4mem=zeros(1024,2,'int32');
    for i=1:16
        [yy,xx]=ind2sub([4 4],i);
        lutxy4mem((i-1)*64+(1:64),:)=[vec(lutX(s+yy-1,s+xx-1)) vec(lutY(s+yy-1,s+xx-1))];
    end
    Utils.buildTracer(dec2hexFast(typecast(vec(lutxy4mem'),'uint64'),16),'DIGG_LUT_LensModel_mem',traceOutDir);
    
    
    
end
%{

    %%
    N = 1:50:length(xold(:));%randperm(length(xold(:)),50000);
    figure(123);clf;
    plot(double(xold(N))/2^shift,double(yold(N))/2^shift,'b.');
    hold on;
    plot(bitshift(xnew(N),-shift),bitshift(ynew(N),-shift),'ro');
    hold off
    title('(x,y) before and after undist');
    legend('old','new');
    axis equal

%}

% lgr.print2file('\t\t\t----- end undist -----\n');


end


function [val,xaddr,yaddr,neighbors,indRowReal,indColReal]= bicubicInterp(lut,regsDIGG,X,Y)
fx = int64(regsDIGG.undistFx);
fy = int64(regsDIGG.undistFy);
x0 = int64(regsDIGG.undistX0);
y0 = int64(regsDIGG.undistY0);
lut=int64(lut);
shift = int16(regsDIGG.bitshift);
sz = size(X);
XX = int64(X(:)) - x0;
YY = int64(Y(:)) - y0;

xaddr = bitshift(XX*fx,-shift);
yaddr = bitshift(YY*fy,-shift);

assert(all(xaddr>=0 & xaddr<=bitshift(32,shift)-1),'udistort: bad LUT x address');
assert(all(yaddr>=0 & yaddr<=bitshift(32,shift)-1),'udistort: bad LUT y address');

[val,indCol,indRow] = Pipe.DIGG.bicubicFixed(lut, xaddr, yaddr, uint8(shift));
indRowReal = reshape(indRow(:),16,sz(1));
indColReal = reshape(indCol(:),16,sz(1));
neighbors = lut(sub2ind(size(lut),indRowReal(:)+1,indColReal(:)+1));
neighbors = reshape(neighbors,[16 sz])';
val = reshape(val,sz);
%neighbors = reshape(neighbors',[16 sz])';
val=int32(val);
end
