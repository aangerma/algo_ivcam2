function [raw,rawstd] = collectDataRF(hw,datapath)
% This function shows a stream of ir images on the screen. It marks the
% center of the image and the title is the distance. When you press a key,
% 50 images are captured, averaged, and the frame + std is recorded.
% After each capture, data is saved to datapath, when 
finish = false;
c = 1;
while ~finish
    [avgd,stdd,finish]=showImageRequestDialog(hw);
    if ~finish
        raw(c) = avgd;
        rawstd(c) = stdd;
        c = c+1;
    end
end
fprintf('Finished capturing images. Saving...');
save(datapath,'raw','rawstd');
fprintf('Done.\n');
end


function [raw,rawstd,finish]=showImageRequestDialog(hw)
finish = false;
f=figure('NumberTitle','off','ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));

%%
while(ishandle(f) && get(f,'userdata')==0)
    
    raw=hw.getFrame();
    subplot(1,2,1)
    imagesc(rot90(raw.i,2));
    subplot(1,2,2)
    imagesc(rot90(raw.z,2));
    hold on
    plot(320,240,'r*')
    figTitle = sprintf('Depth at center pixel: %dmm',raw.z(240,320)/8);
    title(figTitle);
%     colormap(gray(256));
    drawnow;
end
if isvalid(f)
    close(f);
    [raw,rawstd]=readAvgSTDFrameRF(hw,100);
else
    finish = true;
    raw = [];
    rawstd = [];
end




end
function [avgD,stdD] = readAvgSTDFrameRF(hw,K)
z = zeros(1,K);
for i = 1:K
   stream = hw.getFrame(); 
   if stream.i(240,320) == 0
       z(i) = nan;
   else
       z(i) = stream.z(240,320);
   end
end
avgD = mean(z,'omitnan');
stdD = std(z,[],'omitnan');
end