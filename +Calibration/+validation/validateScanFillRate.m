function [ scanFillRate ] = validateScanFillRate( hw ,warmUpFrames)
%VALIDATEFILLRATE calculate the fill rate of the scanlines. 
if ~exist('warmUpFrames','var')
    warmUpFrames = 600;
end
hw.getFrame();
r = Calibration.RegState(hw);
r.add('JFILbypass$'    ,true     );
r.set();
hw.getFrame(warmUpFrames);

nAvg = 30;
nFrames = nAvg;
FR = zeros(nFrames,1);
i = 1;
while i <= nFrames || i>1000
    framesI = hw.getFrame().i;
    
    if any(framesI(:)>0)
        FR(i) = sum(framesI(:)>0)/numel(framesI);
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

