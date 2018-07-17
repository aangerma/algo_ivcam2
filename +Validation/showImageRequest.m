function frames = showImageRequest(hw, target, nFrames, delay)

if (~exist('nFrames','var'))
    nFrames = 100;
end

if (~exist('delay','var'))
    delay = 0;
end


f=figure('NumberTitle','off', 'WindowState', 'maximized', 'ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));
a=axes('parent',f);
maximizeFig(f);
I = mean(target.img, 3);
%%

move2Ncoords = [2/size(I,2) 0 0 ; 0 2/size(I,1) 0; -1/size(I,2)-1 -1/size(I,1)-1 1];

It= imwarp(I, projective2d(move2Ncoords*target.tForm'),'bicubic','fill',0,'OutputView',imref2d([480 640],[-1 1],[-1 1]));
It = (It.*permute([0 1 0],[3 1 2]));

%%
while(ishandle(f) && get(f,'userdata')==0)
    
    if (~isempty(hw))
        ir = double(hw.getFrame().i);
    else
        ir = zeros(480, 640);
    end
    image((repmat(rot90(ir,2)*.8,1,1,3)+It*.25));
    axis(a,'image');
    axis(a,'off');
    title(target.title);
    colormap(gray(256));
    drawnow;
end
close(f);

if (~isempty(hw))
    for i = 1:nFrames
        frames(i) = hw.getFrame();
        if (delay ~= 0)
            pause(delay);
        end
    end
else
    for i = 1:nFrames
        frames(i).z = zeros(480,640, 'uint16');
        frames(i).i = zeros(480,640, 'uint8');
        frames(i).c = zeros(480,640, 'uint8');
    end
end


end

