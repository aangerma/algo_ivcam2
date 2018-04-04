function [imacc,k_depth]=grabImages()
    
    platformCam = ADB;
    hw=HWinterface;
    k_depth=[];%depth intrinsics;
    
    
    f=figure('NumberTitle','off','ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));
    a(1)=subplot(1,2,1,'parent',f);
    a(2)=subplot(1,2,2,'parent',f);
    
    maximizeFig(f);
    
    %%
    d=[-1 1];
    s=0.7;
    shearVals=combvec([-.1 0 .1],[-.1 0 .1])';
    
    I=ones(100,'uint8')*255;
    move2Ncoords = [2/size(I,2) 0 0 ; 0 2/size(I,1) 0; -1/size(I,2)-1 -1/size(I,1)-1 1];
    
    imacc=cell(size(shearVals,1),2);
    
    for i=1:size(shearVals,1)
        
        %%
        while(ishandle(f) && get(f,'userdata')==0)
            tformData=[s 0 0;0 s 0 ;shearVals(i,:) 1];
            
            It= imwarp(I, projective2d(move2Ncoords*tformData'),'nearest','fill',0,'OutputView',imref2d([480 640],d,d));
            
            imC=platformCam.getCameraFrame();
            imD=hw.getFrame().i;
            
            
            if(isempty(imC))
                imC=padarray(str2img('Failed to get\nimage from\nADB device'),[5 5],'both');
                imC=uint8((1-cat(3,imC,imC,imC))*255);
            end
            
            imD = cat(3,imD,(imD+It)/2,It);
            
            
            image(imC,'parent',a(1));axis(a(1),'image');axis(a(1),'off');
            image(imD,'parent',a(2));axis(a(1),'image');axis(a(1),'off');
            drawnow;
        end
        imD=hw.getFrame(30).i;
        imacc(end+1,:)={imD,imC};
    end
    close(f);
end