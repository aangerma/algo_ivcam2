function [pipeOutData] = autopipe(varargin)
%{
options:
    viewResults
    saveTrace
    saveMAT
    verbose
    rewrite
    debug
    fastApprox
    saveResults
    memoryLayout
    regHandle
%}
%% input handle
[fw,p] = Pipe.loadFirmware(varargin{:});



%%
if(isdir(p.ivsFilename))
    ivsFiles = dirFiles(p.ivsFilename,'*.ivs');
    memLayout = Pipe.setDefaultMemoryLayout();
    pipeOutData=[];
    for i=1:length(ivsFiles)
        if(p.verbose)
            fprintf('=======Batch %d/%d=======\n',i,length(ivsFiles));
        end
        pipeOutData = [pipeOutData Pipe.autopipe(ivsFiles{i},varargin{2:end},'memoryLayout',memLayout)];%#ok
        memLayout=pipeOutData(i).memoryLayoutOut;
    end
    if(p.saveResults)
        imwriteAnimatedGif({pipeOutData.iImg},[p.ivsFilename filesep 'buffer_ir.gif']);
        imwriteAnimatedGif({pipeOutData.zImg},[p.ivsFilename filesep 'buffer_depth.gif'],true);
    end
    return
end
    

%%
lgr = Logger(p.verbose,p.saveResults,fullfile(p.outputDir,'log.log'));
[~,fn] = fileparts(p.ivsFilename);
%%
if(~exist(p.calibFile,'file'))
        %------------CALIBRATION BEGIN------------
    calibTic=tic; lgr.print('Calibrating...\n');
    Calibration.runcalibPipe(p.ivsFilename,'calibFile',p.calibFile,'modeFile',p.modeFile);
    lgr.print(' done in %4.2f sec \n', toc(calibTic));
    %------------CALIBRATION END------------
    [fw,p] = Pipe.loadFirmware(varargin{:});
end
%% read .ivs
autoTic=tic;
lgr.print('Executing algo pipe\n');
lgr.print('-------------------\n');
lgr.print('Version:           %s\n', Pipe.version() );
lgr.print('Version location:  %s\n',fileparts(fileparts(which('Pipe.autopipe'))));
lgr.print('Input file:        %s\n',p.ivsFilename);
lgr.print('Host name:         %s\n',iff(isunix,getenv('HOST'),getenv('computername')));
lgr.print('User:              %s\n',iff(isunix,getenv('USER'),getenv('username')));
lgr.print('run started at:    %s\n',datestr(now,'YYYY mmm DD HH:MM:SS'));
%sRUNNING AUTOPIPE: %s\n',fn);
localTic=tic;
lgr.print('\tReading .ivs...');
if(~exist(p.ivsFilename,'file'))
    lgr.error('file %s does not exists',p.ivsFilename);
end
piStruct = io.readIVS(p.ivsFilename);
lgr.print(' done in %4.2f sec \n', toc(localTic));









%% FIRMWARE Settings
fwTic=tic; lgr.print('\tConfiguring Firmware...');

[regs,luts] = fw.get();
    
memoryLayout = p.memoryLayout;

lgr.print2file('\n');
lgr.print2file(fw.disp()');

lgr.print(' done in %4.2f sec \n', toc(fwTic));

%% THE PIPE

%-----------------------------------PIPE BEGIN-----------------------------------%
[pipeOutData,pipeOutData.memoryLayoutOut] = Pipe.hwpipe(piStruct, regs, luts,memoryLayout,lgr,p.traceOutDir);
pipeOutData.regs = regs;
pipeOutData.luts = luts;
pipeOutData.camera.K = reshape([typecast(regs.CBUF.spare,'single')';1],3,3)';
%-----------------------------------PIPE END  -----------------------------------%


%% save results
if(p.saveResults)
    fw.writeConfig4asic([p.outputDir 'RegsConfiguration.ASIC.csv']);
    Pipe.savePipeOutData(pipeOutData,p.outputDir,fn);
    
    if p.saveMAT
        outputMatFilename = [fullfile(p.outputDir,fn),'_results.mat'];
        save(outputMatFilename,'pipeOutData','regs','luts','-v7.3');
    end
    
    lgr.print('\tResults saved in : %s\n',p.outputDir);
end

%% view results
if(p.viewResults)
    img = Pipe.displayPipeOutData(pipeOutData,fn);
    if p.saveResults
        filetosave = fullfile(p.outputDir,sprintf('%s.%s',fn,'png'));
        imwrite(img,filetosave);
    end
end


lgr.print('Autopipe finished in %4.2f sec \n', toc(autoTic));
end


















