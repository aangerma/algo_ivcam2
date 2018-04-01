function  showWithDelays(hw)

f=figure('userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));
axis image; axis off;
colormap(gray(256));
title('Changing delays every fram');

iFrame = uint32(0);

while(ishandle(f) && get(f,'userdata')==0)
    
    %delay = bitand(iFrame*4, 127);
    %Calibration.aux.hwSetDelay(hw, delay, false);
    
    frame = hw.getFrame();
    figure(f); imagesc(frame.i);
    axis equal
    tStr = sprintf('Changing delays every frame: %u', iFrame);
    title(tStr);
    drawnow;
    iFrame = iFrame + 1;
end


end

