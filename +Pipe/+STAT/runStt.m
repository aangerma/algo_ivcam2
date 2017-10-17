function [sttMemoryLayout,CurrImg] = runStt(imageIn,invalidMaskIn,instance,regs,sttMemoryLayout)
    
    % produce icon per frame of size 160X120 from depth / IR / RGB.
    % memory is 160X160 to support 160X120 and 120X160.
    % Statistics over the icon are histograms.
    
    
    
    %% Instance dependant registers
    bypass=               regs.STAT.(sprintf('%sBypass',instance));
    integralImageBypass = regs.STAT.(sprintf('%sintegralImageBypass',instance));
    scaleMode =           regs.STAT.(sprintf('%sscaleMode',instance));
    upperThr =            regs.STAT.(sprintf('%supperThr',instance));
    lowerThr =            regs.STAT.(sprintf('%slowerThr',instance));
    invCntBypass =        regs.STAT.(sprintf('%sinvCntBypass',instance));
    src =                 regs.STAT.(sprintf('%ssrc',instance));
    lowThrPxlNum =        regs.STAT.(sprintf('%slowThrPxlNum',instance));
    cellHsize =           regs.STAT.(sprintf('%scellHsize',instance));
    cellVsize =           regs.STAT.(sprintf('%scellVsize',instance));
    skipHsize =           regs.STAT.(sprintf('%sskipHsize',instance));
    skipVsize =           0;%regs.STAT.(sprintf('%sskipVsize',instance));
    normMult =            regs.STAT.(sprintf('%snormMult',instance));
    invalOrPxl =          regs.STAT.(sprintf('%sinvalOrPxl',instance));
    tCamOutFormat =       regs.STAT.(sprintf('%stCamOutFormat',instance));
    linearReference = regs.STAT.(sprintf('%slinearReference',instance));
    cellCoords =      regs.STAT.(sprintf('%siconCellCoord',instance));
    cellCoords=reshape(cellCoords,4,[]);
    numOfIcons = length(sttMemoryLayout.Icons); % we don't really need this number of icons for ivcam 2.0, we only 2 or 3: one for previous state, and a double buffer for the next state on which we are working.
    iconSize = size(sttMemoryLayout.Icons{1});
    
    CurrImg = []; % for trace
    %transpose image (for matlab implementation)
    
    if (~(bypass))
        % Prepare inputs
        scaleFactor = double((scaleMode));
        switch (src)
            
            case {0 1} % depth\IR input
                inIm = imageIn';
                invalidMaskIn = invalidMaskIn';
                invMask = invalidMaskIn.*(~(invCntBypass));
                invMask(inIm > (upperThr)) = 1;
                invMask(inIm < (lowerThr)) = 1;
                inIm(invMask ==1) = 0;
                if (src) ==0 % depth
                    if scaleFactor < 9
                        inIm = bitshift(inIm, -(8-scaleFactor));
                        inIm(inIm >255)=255;
                    else%default
                        inIm = bitshift(inIm, -8);
                    end
                else %IR
                    if scaleFactor <=4 %change depending on IR size
                        inIm = uint8(bitshift(inIm,-4 + scaleFactor));
                    else
                        inIm = uint8(bitshift(inIm,-4));
                    end

                end
                CurrImg = uint16(inIm) + uint16(invMask)*(2^12);
            case {2 3} % external CAM
                inIm = imageIn;
                
                ScaleMode = double((scaleMode));
                if (tCamOutFormat) == 4
                    if ScaleMode < 10
                        inIm = bitand(inIm,2^(10-ScaleMode)-1);
                        if ScaleMode < 2
                            inIm = bitshift(inIm, -2 + ScaleMode);
                        end
                        
                        inIm(bitshift(inIm,-10+ScaleMode)>0)=255;
                        
                    else
                        inIm(inIm > 0) = 255;
                    end
                end
                
                if ((tCamOutFormat) == 4 ||  (tCamOutFormat) == 5 ||  (tCamOutFormat) == 6)
                    CurrImg = uint16(inIm(:,1:2:end)) + uint16(inIm(:,2:2:end));
                else
                    CurrImg = uint16(inIm);
                end
        end
        
        % Resize input (binning)
        if (((src) == 0) || ((src) == 1 ))
            [icn, vicn] = Pipe.STAT.createIconImage( inIm,invMask,(lowThrPxlNum),...
                (cellHsize), (cellVsize),floor((skipHsize)/2), skipVsize,iconSize);
        else
            [icn] = Pipe.STAT.resize(inIm, (cellHsize), (cellVsize),...
                (skipHsize), skipVsize, (normMult),(src),(tCamOutFormat),iconSize);
            vicn = icn*0;
        end
        
        
        %% Set the right index.
        last_ind = sttMemoryLayout.Position; %+1 for 0 based count +1 for next icon
        if last_ind == numOfIcons
            %if linear reference jump to 2, o.w jump to 1
            icon_ind = 1 + double(linearReference>0);
        else
            icon_ind = last_ind + 1;
        end
        
        % select input image or invalid for histogram
        if((invalOrPxl) && ((src) == 0 || (src) == 1))
            IconImg2hist = uint8(vicn);
        else
            IconImg2hist = uint8(icn);
        end
        
        %calculate temporal icon
        diffIcon = [];
        if(last_ind> 0 )
            if linearReference == 0 %linear mode
                prev_ind = last_ind ;
            else %refrence mode
                prev_ind=1;
            end
            
            prevIcon = sttMemoryLayout.Icons{prev_ind};
            
            diffIcon = uint8(abs(double(IconImg2hist) - double(prevIcon)));
            if (src) == 0 || (src) == 1
                diffIcon(prevIcon == 255 | IconImg2hist == 255) = 255;
            end
            
        end
        
        %calc histograms
        hspat = zeros(12,256);
        htmp = zeros(12,256);
        for r=1:12
            coords = cellCoords(:,r);
            lux = coords(1);
            luy = coords(2);
            rdx = coords(3);
            rdy = coords(4);
            
            % spatial histogram
            spatIconRegion = IconImg2hist(luy+1:1:rdy+1,lux+1:1:rdx+1);
            hspat(r,:) = uint32(histc(uint32(spatIconRegion(:)),0:255));
            
            %temporal histogram
            if ~isempty(diffIcon)
                tempIconRegion = diffIcon(luy+1:1:rdy+1,lux+1:1:rdx+1);
                htmp(r,:) = uint32(histc(uint32(tempIconRegion(:)),0:255));
            end
        end
        
        %store in memory
        sttMemoryLayout.Icons{icon_ind} = IconImg2hist;
        sttMemoryLayout.Position = icon_ind;
        sttMemoryLayout.SpatialHists{icon_ind} = hspat;
        sttMemoryLayout.TemporalHists{icon_ind} = htmp;
        newIntegralImageIcon = Pipe.STAT.integralImage(uint32(IconImg2hist));
        integralImageIndex = sttMemoryLayout.integralImageIndex;
        if (~(integralImageBypass)) %% If enabled, write the new integral image to memory, otherwise memory is untouched.
            sttMemoryLayout.IntegralImage{integralImageIndex+1} = newIntegralImageIcon;
            if (integralImageIndex == 0)
                integralImageIndex  = 1;
            else
                integralImageIndex = 0;
            end
        end
        sttMemoryLayout.integralImageIndex = integralImageIndex;
        %OSS: assert (integralImageIndex == 0 || integralImageIndex ==1 )
    else
        sttMemoryLayout.Position = 0;
    end
    
end

