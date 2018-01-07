clean

%% only check that the math is the same as the hardware
% %     f = figure; maximize(f); hold on;
% %     cnt = 1;
% %     psnr_value = [];
% %     psnrMath = [];
% %     for i=1:10
% %         
% %         
% %         Mcw = uint16(2^6+rand(1)*(2^12-2^6));
% %         [regs, unitTestS] = Calibration.psnrTableGen(Mcw,1);
% %         
% %         figure(f);
% %         stopLine = -5:5;
% %         plot(cnt*ones(size(stopLine)),stopLine,'k')
% %         text(cnt,5,['Mcw = ' num2str(Mcw)])
% %         
% %         for j=1:100
% %             MsSim = uint16(rand(1)*(2^12-1));
% %             MnSim = uint16(rand(1)*MsSim);
% %             
% %             
% %             
% %             %% PSNR code snip from DCOR (minor changes in comments)
% %             iImgRAW = MsSim; %iImgRAW = pflow.iImgRAW;
% %             dIR = max(0, int16(iImgRAW)-int16(regs.DCOR.irStartLUT));
% %             irIndex = map(regs.DCOR.irMap,    min(63, bitshift(dIR, -int8(regs.DCOR.irLUTExp))  )   +1);
% %             
% %             amb = MnSim; %amb = pflow.aImg;
% %             dAmb = max(0, int16(amb)-int16(regs.DCOR.ambStartLUT));
% %             ambIndex = map(regs.DCOR.ambMap, min(63, bitshift(dAmb, -int8(regs.DCOR.ambLUTExp)))+1);
% %             
% %             psnrIndex = bitor(bitshift(ambIndex, 4), irIndex);
% %             psnr_value(end+1) = map(regs.DCOR.psnr, uint16(psnrIndex)+1);
% %             
% %             
% %             
% %             
% %             
% %             %% PSNR math calc
% %             psnrT = unitTestS.psnrT;
% %             psnrT(isnan(psnrT)) = 0;
% %             psnrMath(end+1) = psnrT(minind(abs(unitTestS.Ms-double(MsSim))),minind(abs(unitTestS.Mn-double(MnSim))));
% %             
% %             plot(cnt,psnr_value(end)-psnrMath(end),'b*')
% %             cnt = cnt+1;
% %             drawnow
% %         end
% %     end
% %     
% %     title(['test psnrTableGen: error = psnrLUT-psnrMath; mean error = ' num2str(mean(psnr_value-psnrMath)) '; std error = ' num2str(std(psnr_value-psnrMath))])
% % end


%%
McwArr = uint16(2.^(7:1:12));
 
f = figure(25231);clf
for i=1:length(McwArr)
   
    
    Mcw = McwArr(i);
     
    [regs, unitTestS] = Calibration.psnrTableGen(Mcw,1);
    
        MsArr = uint16(linspace(0,max(unitTestS.Ms),100));
    MnArr = uint16(linspace(0,max(unitTestS.Mn),100));
    
    
    
    psnr_value = zeros(length(MsArr),length(MnArr));
    psnrMath = zeros(length(MsArr),length(MnArr));
    for j=1:length(MsArr)
        MsSim = uint16(MsArr(j));
        for k=1:length(MnArr)
            MnSim = uint16(MnArr(k));
            
            
            
            %% PSNR code snip from DCOR (minor changes in comments)
            iImgRAW = MsSim; %iImgRAW = pflow.iImgRAW;
            dIR = max(0, int16(iImgRAW)-int16(regs.DCOR.irStartLUT));
            irIndex = map(regs.DCOR.irMap,    min(63, bitshift(dIR, -int8(regs.DCOR.irLUTExp))  )   +1);
            
            amb = MnSim; %amb = pflow.aImg;
            dAmb = max(0, int16(amb)-int16(regs.DCOR.ambStartLUT));
            ambIndex = map(regs.DCOR.ambMap, min(63, bitshift(dAmb, -int8(regs.DCOR.ambLUTExp)))+1);
            
            psnrIndex = bitor(bitshift(ambIndex, 4), irIndex);
            psnr_value(j,k) = map(regs.DCOR.psnr, uint16(psnrIndex)+1);
            
            
            
            
            
            %% PSNR math calc
            psnrT = unitTestS.psnrT;
            psnrT(isnan(psnrT)) = 0;
            psnrMath(j,k) = psnrT(minind(abs(unitTestS.Ms-double(MsSim))),minind(abs(unitTestS.Mn-double(MnSim))));
        end
    end
    
    errorMat = abs(psnr_value-psnrMath);
    errorMat(errorMat>2)=-1;
    figure(f);tabplot;
    imagesc([MnArr(1),MnArr(end)], [MsArr(1),MsArr(end)], errorMat);
    ylabel('Ms == ir');xlabel('Mn == nest');colorbar;title(['Mcw = ' num2str(Mcw)]);
    colorbar
    drawnow
    
%      figure;imagesc([MnArr(1),MnArr(end)], [MsArr(1),MsArr(end)], psnr_value);
%     ylabel('Ms == ir');xlabel('Mn == nest');colorbar;title(['Mcw = ' num2str(Mcw)]);
%     drawnow
%     
%        figure;imagesc([MnArr(1),MnArr(end)], [MsArr(1),MsArr(end)], psnrMath);
%     ylabel('Ms == ir');xlabel('Mn == nest');colorbar;title(['Mcw = ' num2str(Mcw)]);
%     drawnow
end






