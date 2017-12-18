function pipeOutData = runPipe(ivsFn,changeFW)
% mcc -m runPipe.m -d '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\YONI\runPipe\' -a ..\..\+Pipe\tables\* 
if(naragin==0)
    ivsFn=uigetdir;
    if(ivsFn==0)
        return;
    end
end
if(nargin<2)
    changeFW = 0;
end

if(changeFW)
  
    
    
    [fw,p] = Pipe.loadFirmware(ivsFn);
    regs = fw.get();
    regsNew = structDlg(regs);
    fw.setRegs(regsNew,[])
    fw.writeUpdated(p.configFile);
    fw.writeUpdated(p.modeFile);
    fw.writeUpdated(p.calibFile);
end


pipeOutData = Pipe.autopipe(ivsFn);
end