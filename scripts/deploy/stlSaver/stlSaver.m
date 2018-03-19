function stlSaver
%mcc -m stlSaver.m  -a ..\..\..\+Pipe\tables\ -a ..\..\..\@Firmware\presetScripts
wd = [cd filesep];
stldir = [wd 'stl' filesep];
fns = dirFiles(wd,'*.csv');


mkdirSafe(stldir);

fw=Firmware;
fprintf('stl directory %s\n csv files:\n',stldir);
for i=1:length(fns)
    fw.setRegs(fns{i});
    fprintf('%s\n',fns{i});
end
hw = HWinterface(fw);
regs = fw.get();
f=figure('NumberTitle','off','ToolBar','none','MenuBar','none','userdata',0,'KeyPressFcn',@(varargin) set(varargin{1},'userdata',1));
maximizeFig(f);
counter = 0;
while(ishandle(f))
    
    while(get(f,'userdata')==1)
        d = hw.getFrame();
        sbuplot(121);
        imagesc(d.z);
        axis image;
        sbuplot(122);
        imagesc(d.i);
        axis image;
        drawnow;
        
    end
    set(f,'userdata'==1);
    
    v=Pipe.z16toVerts(d.z,regs);
    stlfn = sprintf('%sv%04d.stl',stldir,counter);
    counter=counter+1;
    stlwriteMatrix(stlfn,v(:,:,1),v(:,:,2),-v(:,:,3),'color',d.i,'facetsDirUp',true);
    fprintf('wrote %s\n',stlfn);
end



end