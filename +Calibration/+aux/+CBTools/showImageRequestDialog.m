function raw=showImageRequestDialog(hw,figNum,tformData)
    persistent figImgs;
    figTitle = 'Please align image board to overlay';
    if(isempty(figImgs))
        bd = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'targets',filesep);
        figImgs{1} = imread([bd 'calibrationChart.png']);
        figImgs{2} = imread([bd 'fineCheckerboardA3.png']);
    end
    
    f=figure('NumberTitle','off','ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));
    a=axes('parent',f);
    maximizeFig(f);
    I = mean(figImgs{figNum},3);
    %%
    
    move2Ncoords = [2/size(I,2) 0 0 ; 0 2/size(I,1) 0; -1/size(I,2)-1 -1/size(I,1)-1 1];
    
    It= imwarp(I, projective2d(move2Ncoords*tformData'),'bicubic','fill',0,'OutputView',imref2d([480 640],[-1 1],[-1 1]));
    It = uint8(It.*permute([0 1 0],[3 1 2]));
    
    %%
    while(ishandle(f) && get(f,'userdata')==0)
        
        raw=hw.getFrame(-1);
        %recored stream
        if(all(raw.i(:)==0))
            break;
        end
        image(uint8(repmat(rot90(raw.i,2)*.8,1,1,3)+It*.25));
        axis(a,'image');
        axis(a,'off');
        title(figTitle);
        colormap(gray(256));
        drawnow;
    end
    close(f);
    
    raw=hw.getFrame(30);
    
end
