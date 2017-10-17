function analyzeModes(modeName,scene,inputDir)

    sceneMode = sprintf('%s-%s',scene,modeName);
    load(fullfile(inputDir,'output',sceneMode,sprintf('%s.mat',sceneMode)));

    % RMS calculations 
    zImgMM = double(pipeOutData.zImg) / regs.GNRL.zNorm; % depth image in [mm]    
    GTzImgMM = double(GTpipeOutData.zImg) / GTregs.GNRL.zNorm; % depth image in [mm]
    zeroVals = (pipeOutData.cImg==0 | zImgMM==0 | pipeOutData.iImg==0);
    GTzeroVals = (GTpipeOutData.cImg==0 | GTzImgMM==0 | GTpipeOutData.iImg==0);
    cZeroVals = GTzeroVals; % Default, would probably be changed
    if size(zeroVals) == size(GTzeroVals)
        cZeroVals = zeroVals | GTzeroVals;
    end 
    %%%%%%%% Ask Ohad - also ignore zeros in the JFILed image? or only GT?
    %%%%%%%% (improved the depth, not the ir)
    %%%%%%%% how should i calculate the zerovals? only from confidence and
    %%%%%%%% depth? or ir too?
    %%%%%%%% How should I calculate the difference when the resolution is
    %%%%%%%% changed?

    RMSz = sqrt(mean((zImgMM(~cZeroVals) - GTzImgMM(~cZeroVals)).^2));
    RMSi = sqrt(mean((double(pipeOutData.iImg(~cZeroVals)) - double(GTpipeOutData.iImg(~cZeroVals))).^2));

    % Histogram & STD
    sdtz = std(zImgMM(~cZeroVals) - GTzImgMM(~cZeroVals));
    fz = figure;
    histogram(zImgMM(~cZeroVals) - GTzImgMM(~cZeroVals));
    title(sprintf('%s mode: \nZ hist\n STD = %0.3f RMS = %0.3f',sceneMode,sdtz,RMSz))

    sdti = std(double(pipeOutData.iImg(~cZeroVals)) - double(GTpipeOutData.iImg(~cZeroVals)));
    fi = figure;
    histogram(double(pipeOutData.iImg(~cZeroVals)) - double(GTpipeOutData.iImg(~cZeroVals)));
    title(sprintf('%s mode: \nIR hist\n STD = %0.3f RMS = %0.3f',sceneMode,sdti,RMSi))

end
