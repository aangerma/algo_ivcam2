function [Sout] = resize(Iin, CHSize, CVSize, SkipH, SkipV,...
        NormMult,RegsSttsSrc,RegsTcamOutFormat,iconSize)
    Sout = zeros(iconSize);
    if CVSize <= 0,
        error('ZERO VSize!! Resetting to 1');
    end
    
    pxlPerCycle = 1;
    
    if RegsSttsSrc ~= [1,2,3,5]
        pxlPerCycle = 2;
    end
    
    if ( RegsTcamOutFormat == 4 || RegsTcamOutFormat == 5|| RegsTcamOutFormat == 6)
        pxlPerCycle = 2;
    end
    
    NormMult = min(NormMult, 1023);
    SkipH = floor(SkipH*pxlPerCycle/2);
    CHSize = CHSize*pxlPerCycle;
    S = uint32(Pipe.STAT.my_blkproc(Iin(1:end-SkipV, [1+SkipH:end-SkipH]), [CVSize CHSize], @(x)(sum(double(x(:))))));
    if ~isempty(S)
        S = bitshift(S * uint32(NormMult), -13);
        
        S = uint8(min(S(1:min(end,iconSize(1)),1:min(end,iconSize(2))),255));
        Sout(1:size(S,1),1:size(S,2)) = S;
    end
end
