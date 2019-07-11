function raw=showImageRequestDialog(hw,figNum,tformData,figInTitle,nFrames,mask)
    persistent figImgs;
    if ~exist('figInTitle','var') || isempty(figInTitle)
        figInTitle = 'Please align image board to overlay';
    end
    if ~exist('nFrames','var') || isempty(nFrames)
        nFrames = 45;
    end
    sz = hw.streamSize();
    if(isempty(figImgs))
        bd = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))),'targets',filesep);
        figImgs{1} = imread([bd 'sampleCalibrationChart.png']);
        figImgs{2} = imread([bd 'fineCheckerboardA3.png']);
        if exist('mask','var')
            figImgs{3} = mask;
        else
            figImgs{3} = uint8(zeros([sz,3]));
        end
    else
        if exist('mask','var')
            figImgs{3} = mask;
        else
            figImgs{3} = uint8(zeros([sz,3]));
        end
    end
    f=figure('NumberTitle','off','ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@exitOnEnter,'WindowButtonDownFcn',@(varargin) set(varargin{1},'userdata',1));
    a=axes('parent',f);
    maximizeFig(f);
    I = 255-mean(figImgs{figNum},3);
    %%
    
    move2Ncoords = [2/size(I,2) 0 0 ; 0 2/size(I,1) 0; -1/size(I,2)-1 -1/size(I,1)-1 1];
    if ~isempty(tformData)
        It = imwarp(I, projective2d(move2Ncoords*tformData'),'bicubic','fill',0,'OutputView',imref2d(sz,[-1 1],[-1 1]));
        It = uint8(It.*permute([0 1 0],[3 1 2]));
    else
        It = uint8(zeros([sz,3]));
    end
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
        if exist('mask','var')
            maskLogic = ~logical(mask);
            trgDist = mean(raw.z(maskLogic))./4;
            figTitle = [figInTitle '. ROI is at Distance: ' num2str(trgDist,'%4.1f') ' mm'];
        else
            figTitle = figInTitle;
        end
        title(figTitle);
        colormap(gray(256));
        drawnow;
    end
    close(f);
    
    raw=hw.getFrame(nFrames);
    
end
function exitOnEnter(figHandle,varargin)
    key = get(figHandle,'CurrentKey');
    if (strcmp (key , 'return'))
        set(figHandle,'userdata',1);
    end
end