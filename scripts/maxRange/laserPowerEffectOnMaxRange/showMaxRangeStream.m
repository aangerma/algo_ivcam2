function [fillRate,zStd,zMean]=showMaxRangeStream(hw)
    
    
    f=figure('NumberTitle','off','ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@exitOnEnter,'WindowButtonDownFcn',@(varargin) set(varargin{1},'userdata',1));
    a=axes('parent',f);
%     maximizeFig(f);
    %%
    sz = hw.streamSize();
    
    params = Validation.aux.defaultMetricsParams();
    params.camera.zMaxSubMM = hw.z2mm;
    params.roi = 0.1;
    mask = Validation.aux.getRoiMask(double(sz), params);
    
    %%
    fi = 1;
    maxframes = 30;
    while(ishandle(f) && get(f,'userdata')==0)
        
        raw=hw.getFrame(-1);
        frames(fi) = raw;
        fi = mod(fi,maxframes) + 1;
        %recored stream
        if(all(raw.i(:)==0))
            break;
        end
        subplot(121);
        imagesc(uint8(rot90(raw.i,2)*.8+255*uint8(mask)*.25));
        [fillRate,~] = Validation.metrics.fillRate(raw,params);
        [zStd,~] = Validation.metrics.zStd(frames,params);
        
        valid = raw.z>0.*mask;
        zMean = mean(raw.z(valid))/double(params.camera.zMaxSubMM);
    
        title(sprintf('Fill Rate = %.0f. zStd = %.2g. zMean = %.0f',fillRate,zStd,zMean));
        subplot(122);
        imagesc((rot90(raw.z,2)/double(params.camera.zMaxSubMM)));
        drawnow;
    end
    close(f);
    
    
    
end
function exitOnEnter(figHandle,varargin)
    key = get(figHandle,'CurrentKey');
    if (strcmp (key , 'return'))
        set(figHandle,'userdata',1);
    end
end