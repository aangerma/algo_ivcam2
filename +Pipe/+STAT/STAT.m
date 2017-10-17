function [ memoryLayout ] = STAT( pflow,memoryLayout,regs,luts,traceOutDir )
%STAT executes STT1-3 blocks acording to regs with the given memory
%layout
depth = pflow.zImg;
ir = pflow.iImg;

switch (regs.STAT.stt1src)
    case {0}
        stt1In = depth;
    case {1}
        stt1In = ir;
    case{2,3}
        [stt1In,ftcam1]=Pipe.STAT.create_tcam_in([regs.MTLB.tCamVsize, regs.MTLB.tCamHsize], regs.STAT.stt1tCamOutFormat,0,0);
end

switch (regs.STAT.stt2src)
    case {0}
        stt2In = depth;
    case {1}
        stt2In = ir;
    case{2,3}
        [stt2In,ftcam2]=Pipe.STAT.create_tcam_in([regs.MTLB.tCamVsize, regs.MTLB.tCamHsize], regs.STAT.stt2tCamOutFormat,0,0);
end

skipVsize1 =  regs.STAT.stt1skipVsize/size(stt1In,2);
skipVsize2 =  regs.STAT.stt2skipVsize/size(stt2In,2);

[memoryLayout.STT1, CurrIm1] = Pipe.STAT.runStt(stt1In(1+skipVsize1:end,:) , stt1In(1+skipVsize1:end,:)==0,'stt1',regs,memoryLayout.STT1);
[memoryLayout.STT2, CurrIm2] = Pipe.STAT.runStt(stt2In(1+skipVsize2:end,:) , stt2In(1+skipVsize2:end,:)==0,'stt2',regs,memoryLayout.STT2);

if ~isempty(traceOutDir)
    
    [IconMem1,HistMem1,integMem1] = Pipe.STAT.exportSttMemoryLayoutToBuff(memoryLayout.STT1);
    [IconMem2,HistMem2,integMem2] = Pipe.STAT.exportSttMemoryLayoutToBuff(memoryLayout.STT2);
    
    
    Utils.buildTracer(dec2hexFast(CurrIm1',4)            ,['STAT_stt1_' 'curr_im'],traceOutDir);
    Utils.buildTracer(dec2hexFast(uint8(IconMem1'),2)    ,['STAT_stt1_' 'stt_icon'],traceOutDir);
    Utils.buildTracer(dec2hexFast(uint16(HistMem1{1}'),4),['STAT_stt1_' 'temp_hist'],traceOutDir);
    Utils.buildTracer(dec2hexFast(uint16(HistMem1{2}'),4),['STAT_stt1_' 'spat_hist'],traceOutDir);
    Utils.buildTracer(dec2hexFast(uint32(integMem1'),8  ),['STAT_stt1_' 'stt_integ'],traceOutDir);
    if exist('ftcam1','var')
        Utils.buildTracer(dec2hexFast(uint32(ftcam1'),8),['STAT_stt1_' 'tcam_in'],traceOutDir);
    end
    Utils.buildTracer(dec2hexFast(CurrIm2',4),['STAT_stt2_' 'curr_im'],traceOutDir);
    Utils.buildTracer(dec2hexFast(uint8(IconMem2'),2),['STAT_stt2_' 'stt_icon'],traceOutDir);
    Utils.buildTracer(dec2hexFast(uint16(HistMem2{1}'),4),['STAT_stt2_' 'temp_hist'],traceOutDir);
    Utils.buildTracer(dec2hexFast(uint16(HistMem2{2}'),4),['STAT_stt2_' 'spat_hist'],traceOutDir);
    Utils.buildTracer(dec2hexFast(uint32(integMem2'),8),['STAT_stt2_' 'stt_integ'],traceOutDir);
    if exist('ftcam2','var')
        Utils.buildTracer(dec2hexFast(uint32(ftcam2'),8),['STAT_stt2_' 'tcam_in'],traceOutDir);
    end
    %fprintf(ficon,'%02x%02x%02x%02x\n',flipud(reshape(IconOut',4,[])));
    %fprintf(fhist,'%04x%04x\n',flipud(reshape(HistMem',2,[])));
    
    
end

end


