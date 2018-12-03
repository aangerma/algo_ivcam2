function [valPassed, valResults] = validateCalibration(runParams,calibParams,fprintff,spark)
    
    if(~exist('spark','var'))
        spark=[];
    end
    write2spark = ~isempty(spark);
    
    valPassed = false;
    valResults = [];
    if runParams.validation
        fprintff('[-] Validation...\n');
        hw = HWinterface();
        hw.getFrame;
        fprintff('opening stream...');
        frame = Calibration.aux.CBTools.showImageRequestDialog(hw,1,diag([.6 .6 1]));
        
        ff = Calibration.aux.invisibleFigure();
        subplot(1,3,1); imagesc(frame.i); title('Validation I');
        subplot(1,3,2); imagesc(frame.z/8); title('Validation Z');
        subplot(1,3,3); imagesc(frame.c); title('Validation C');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','Frame');
        
        stream = hw.getFrame(100,0);
        r=Calibration.RegState(hw);
        r.add('JFILbypass$'        ,true    );
        r.add('DIGGgammaScale', uint16([256,256]));
        r.set();
        pause(0.1);
        
        scanLinesFrame = hw.getFrame();
        ff = Calibration.aux.invisibleFigure();
        imagesc(scanLinesFrame.i); title('Validation Scan Lines Frame');
        Calibration.aux.saveFigureAsImage(ff,runParams,'Validation','scanLinesFrame');
        
        r.reset();
        hw.cmd('mwd a0020a6c a0020a70 04000400 // DIGGgammaScale'); % Todo - fix regstate to read gammascale correctly
        hw.shadowUpdate;
        
        
        fprintff('Done.\n');
        params = Validation.aux.defaultMetricsParams();
        params.roi = 0.5;
         [~, sharpRes] = Validation.metrics.gridEdgeSharp(frame, []);
        valResults.horizontalSharpness = sharpRes.horizMean;
        valResults.verticalSharpness = sharpRes.vertMean;
        [tns] = Validation.metrics.zStd(stream, params);
        valResults.temporalNoise = tns;
        
        delayRes = Calibration.validation.validateDelays(hw,calibParams,fprintff);
        dfzRes = Calibration.validation.validateDFZ(hw,frame,fprintff);
        roiRes = Calibration.validation.validateROI(hw,calibParams,fprintff);
        losRes = Calibration.validation.validateLOS(hw,runParams,fprintff);
        dsmRes = Calibration.validation.validateDSM(hw,fprintff);
        valResults = Validation.aux.mergeResultStruct(valResults,delayRes,...
            dfzRes,roiRes,losRes,dsmRes);
        
        Calibration.aux.logResults(valResults,runParams,'validationResults.txt');
        Calibration.aux.writeResults2Spark(valResults,spark,calibParams.validationErrRange,write2spark);
        valPassed = Calibration.aux.mergeScores(valResults,calibParams.validationErrRange,fprintff);
        
        %{
        fprintff('%s: %2.2gmm\n','zSTD',zSTD);
        fprintff('%s: %2.2g\n','horizSharpnessMean',results.horizMean);
        fprintff('%s: %2.2g\n','vertSharpnessMean',results.vertMean);
       
        fprintff('Validation finished.\n');
        %}
    end
    
end
function saveValidationFrames(frame,runParams,postFix)
    dirname = fullfile(runParams.outputFolder,'captures');
    mkdirSafe(dirname);
    
    f = fieldnames(frame);
    for i = 1:length(f)
        imfn = fullfile(dirname,strcat('validation_frame_',f{i},postFix,'.png'));
        imwrite(frame.(f{i}),imfn);
    end
    
end