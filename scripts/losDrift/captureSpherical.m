function [frames, regs] = captureSpherical(hw, nFrames, delay, verbose)

if ~exist('delay','var')
    delay = 0;
end

if ~exist('verbose','var')
    verbose = false;
end

tic;
for i = 1:nFrames
    frames(i) = hw.getFrame();
    %frames(i).i = fillInternalHolesMM(frames(i).i);
    [temp.ldd,temp.mc,temp.ma,temp.tSense,temp.vSense]=hw.getLddTemperature;
    temps(i) = temp;
    times(i) = toc;
    if (delay ~= 0)
        pause(delay);
    end
    if (verbose)
        figure(171); imagesc(frames(i).i);
        title(sprintf('frame %u of %u, time %.2f sec, temp: %.2f deg,',...
            i, nFrames, toc,temp.ldd));
    end
end

regs.EXTL.dsmXscale=typecast(hw.read('EXTLdsmXscale'),'single');
regs.EXTL.dsmYscale=typecast(hw.read('EXTLdsmYscale'),'single');
regs.EXTL.dsmXoffset=typecast(hw.read('EXTLdsmXoffset'),'single');
regs.EXTL.dsmYoffset=typecast(hw.read('EXTLdsmYoffset'),'single');
regs.DIGG.sphericalOffset = typecast(hw.read('sphericalOffset'), 'int16');
regs.DIGG.sphericalScale = typecast(hw.read('sphericalScale'), 'int16');

for i = 1:nFrames
    frames(i).lddTemp = temps(i).ldd;
    frames(i).temp = temps(i);
    frames(i).time = times(i);
end

fileName = sprintf('checkerSperical_%4.1fdeg_%s.mat', frames(1).lddTemp, datetime);
fileName = strrep(fileName, ':','');
fileName = strrep(fileName, ' ','_');
save(fileName, 'frames', 'regs');

end

