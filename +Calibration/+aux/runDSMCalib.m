function calibRegs = runDSMCalib(hw,regs,margin)
% run dsm calib finds values for:
% DSM shiftX,shiftY,scaleX,scaleY such that the range of angles received
% from the mirror are in the range (1-margin)*[-2047,2047]. 
% This prevents clipping and gives us the full image. 
% The angles received are going through the following coputation:
% ang_final = scale*(ang_orig-shift)
angMax = 2047;
wh = [640,480];
% write our dsm values that scales down the data such that none of it is
% clipped:
xShift = 0.5;
yShift = 0.5;
xScale = 3600;
yScale = 3600;

hw.runCommand('mwd  fffe382c fffe3830 3F000000  //dsm vertical shift')  % ->0.5
hw.runCommand('mwd  fffe3830 fffe3834 45610000  //dsm vertical scale')  % ->3600
hw.runCommand('mwd  fffe3840 fffe3844 3F000000  //dsm horizontal shift')% ->0.5
hw.runCommand('mwd  fffe3844 fffe3848 45610000  //dsm horizontal scale')% ->3600

% Get first image:
d = hw.getFrame();
% Get the biggest blob - the pincushion - eventually all of it should be in the frame.
ir = d.i;
CC = bwconncomp(ir>0);
numPixels = cellfun(@numel,CC.PixelIdxList);
[biggest,idx] = max(numPixels);
irClean = zeros(size(ir));
irClean(CC.PixelIdxList{idx}) = 1;

% Get the 4 corners of the pincushion by measuring distance to image
% corners:
[gy,gx] = ndgrid(1:wh(2),1:wh(1));
yx = [gy(:),gx(:)];
yxValid = yx(logical(irClean(:)),:);

corners = [1,1; wh(2),1; wh(2),wh(1); 1,wh(1)];
closePoints = zeros(4,2);
for i = 1:4
    dist = sum((yxValid-corners).^2,2);
    [~,idx] = min(dist);
    closePoints(i,:) = yxValid(IDX,:);
end


[angx,angy]=Pipe.CBUF.FRMW.xy2ang(closePoints(:,2),closePoints(:,1),regs);

nMinAngX = min(angx)/xScale+xShift;
nMinAngY = min(angy)/yScale+yShift;
nMaxAngX = max(angx)/xScale+xShift;
nMaxAngY = max(angy)/yScale+yShift;

% The minimal x/y angle should be translated to a marginal distance from
% the edge of the resolution:
% a*[minAngX]-b = [-angMax*(1-margin)]
% a*[maxAngX]-b = [ angMax*(1-margin)]
newXScale = 2*(angMax*(1-margin))/(nMaxAngX-nMinAngX);
newXShift = (newXScale*nMinAngX + angMax*(1-margin))/newXScale;

newYScale = (angMax*(1-2*margin))/(nMaxAngY-nMinAngY);
newYShift = newYScale*nMinAngY - angMax*margin;

% New commands:
hw.runCommand(add2Cmd('mwd  fffe382c fffe3830',newYShift));
hw.runCommand(add2Cmd('mwd  fffe3830 fffe3834',newYscale));
hw.runCommand(add2Cmd('mwd  fffe3840 fffe3844',newXShift));
hw.runCommand(add2Cmd('mwd  fffe3844 fffe3848',newXscale));

dPost = hw.getFrame();
figure,
subplot(1,2,1)
imagesc(d.i)
subplot(1,2,2)
imagesc(dPost.i)


end

function add2Cmd(str,num)
    nHex = single2hex(num);
    return [str,sprintf(' %s',nHex{1})];
end