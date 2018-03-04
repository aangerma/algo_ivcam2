function stlSaver
%mcc -m stlSaver.m  -a ..\..\..\+Pipe\tables\*
wd = [cd filesep];
stldir = [wd 'stl' filesep];
rawdir = [wd 'raw' filesep];
cfgfn = [wd 'config.csv'];
fprintf('raw directory: %s\nstl directory %s\nconfiguration file:%s\n',stldir,rawdir,cfgfn);
mkdirSafe(stldir);
mkdirSafe(rawdir);
fw=Firmware;
fw.setRegs(cfgfn)
regs = fw.get();
while(true)
    d=io.readZIC(rawdir);
    for i=1:length(d)
    stlfn=sprintf('%svertices_%04d.stl',stldir,d(i).index);
    if(exist(stlfn,'file'))
        continue;
    end
    v=Pipe.z16toVerts(d(i).z,regs);
    stlwriteMatrix(stlfn,v(:,:,1),v(:,:,2),v(:,:,3),'color',d(i).i,'facetsDirUp',false);
    fprintf('wrote %s\n',stlfn);
    end
    fprintf('.');
    pause(1);
    
end
end