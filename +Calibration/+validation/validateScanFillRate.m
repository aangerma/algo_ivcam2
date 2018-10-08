function [ scanFillRate ] = validateScanFillRate( hw )
%VALIDATEFILLRATE calculate the fill rate of the scanlines. 

hw.getFrame();
r = Calibration.RegState(hw);
r.add('JFILbypass$'    ,true     );
r.set();

nAvg = 30;
nFrames = nAvg+600;
FR = zeros(nFrames,1);
i = 1;
while i <= nFrames || i>1000
    framesZ = hw.getFrame().z;
    if any(framesZ>0)
        FR(i) = sum(framesZ(:)>0)/numel(framesZ);
        i = i+1;
    end
%     if mod(i-1,10) ~= 0 && i < 200
%        tabplot;
%        imagesc(framesZ>0);
%     end
end
if i > 1000
   warning('validateScanFillRate: z image is constant 0.'); 
end
r.reset();

% plot(FR);
scanFillRate = 100*mean(FR(end-nAvg+1:end));


end

