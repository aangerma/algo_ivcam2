function [ statLayout ] = initMem( )
    
    iconSize = [160,160];
    numOfHist = 12;
    histSize = 256;
    
    iconMem = zeros(iconSize,'uint8');
    icons = repmat({iconMem},[1,4]);
    
    histMem = zeros([numOfHist histSize],'uint32');
    hists = repmat({histMem},[1,4]);
  
    integralImgIconMem = zeros(iconSize,'uint32');
    integralImage = repmat({integralImgIconMem},[1,2]);
        
    %set the memory layout to its initial state (after powerup)
    statLayout = [];
    statLayout.Icons = icons;
    statLayout.SpatialHists = hists;
    statLayout.TemporalHists = hists;
    statLayout.IntegralImage=integralImage;
    statLayout.Position = 0;
    statLayout.integralImageIndex = 0; % Possible values are 0 or 1.
    
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
end

