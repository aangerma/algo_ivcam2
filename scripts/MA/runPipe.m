function pipeOutData = runPipe(ivsFn,changeFW)
% mcc -m runPipe.m -d '\\ger\ec\proj\ha\perc\SA_3DCam\Algorithm\YONI\runPipe\' -a ..\..\+Pipe\tables\* 

if(nargin<2)
    changeFW = 0;
end

if(changeFW)
    path = fileparts(ivsFn);
    
    p.calibFile= fullfile(path,'calib.csv');
    p.configFile= fullfile(path,'config.csv');
    p.debug= -1;
    p.fastApprox= -1;
    p.modeFile= fullfile(path,'mode.csv');
    p.regHandle= 'throw';
    p.rewrite= 0;
    p.ivsFilename= ivsFn;

    
    
    [fw,regs] = Pipe.fw4pipe(p);
      
    regsNew = structDlg(regs);
    fw.setRegs(regsNew,'')
    fw.writeUpdated(p.configFile);
    fw.writeUpdated(p.modeFile);
    fw.writeUpdated(p.calibFile);
end


pipeOutData = Pipe.autopipe(ivsFn);
end