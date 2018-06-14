function [imacc,k_depth]=grabImagesN(N)
    if(~exist('N','var'))
        N=30;
    end
    
    platformCam = ADB;
    hw=HWinterface;
    k_depth=reshape([typecast(hw.read('CBUFspare'),'single');1],3,3)';%depth intrinsics;
    
    
    f=figure('NumberTitle','off','ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));
    a(1)=subplot(1,1,1,'parent',f);
    
    
    maximizeFig(f);
    
    %%
    
    
    
    
    imacc=cell(N,3);
    i=1;
    while(true)
        
        %%
        set(f,'userdata',0);
        while(ishandle(f) && get(f,'userdata')==0)
            
            imD=hw.getFrame().i;
            imD = flipud(imD);
            
            image(imD,'parent',a(1));axis(a(1),'image');axis(a(1),'off');
            title(sprintf('%d/%d',i,N));
            drawnow;colormap(gray(256))
        end
        
        imC=platformCam.getCameraFrame();
        if(isempty(imC))
            continue;
        end
        d=hw.getFrame();
        
        imacc(i,:)={d.z,d.i,imC};%#oks
        i=i+1;
        if(i==N)
            break;
        end
        
    end
    close(f);
end