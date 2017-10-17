function ivlpifns = scopeFolder2ivs(baseDir,pocVer)


fwConfigfn = [baseDir '\Config.csv'];
fw = Firmware();
if(exist(fwConfigfn,'file'))
    fw.setRegs(fwConfigfn);
end
regs = fw.getRegs();



rawfns = dirFiles(baseDir,'*.h5');

if(isempty(rawfns))
    error('No input files in directory %s',baseDir);
end


%%  run analog pipe for all files
for i=1:length(rawfns)
    [~,fn]=fileparts(rawfns{i});
    
    fileIVL = fullfile(baseDir, [fn '.ivs']);
    if( exist(fileIVL,'file'))
        continue;
    end
    fprintf('scopeFolder2ivlpi: %s...\n',fn);
%     try
        switch(lower(pocVer))
            case 'poc1'
                ivs = io.POC.scopePOC1data2ivs(rawfns{i},regs);
            case 'poc3'
                ivs = io.POC.scopePOC3data2ivs(rawfns{i},regs);
            otherwise
                error('unknwon poc version')
        end
        fprintf('scopeFolder2ivlpi: %s done\n',fn);
        io.writeIVS(fileIVL, ivs);
%     catch e
%         fprintf('%s\n',e.message);
%     end
%     
    
end




ivlpifns = dirFiles(baseDir,'*.ivs');
end