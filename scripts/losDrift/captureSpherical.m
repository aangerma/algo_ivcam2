function [frames, regs] = captureSpherical(hw, nFrames, delay, tempEveryFrame, verbose)

if ~exist('delay','var')
    delay = 0;
end

if ~exist('tempEveryFrame','var')
    tempEveryFrame = false;
end

if ~exist('verbose','var')
    verbose = false;
end

times = zeros(1,nFrames);
temps = zeros(1,nFrames);

initTemp = [];
if (~tempEveryFrame)
    [temp.ldd,temp.mc,temp.ma,temp.tSense,temp.vSense]=hw.getLddTemperature;
    initTemp = temp;
end

frames(1:100) = struct('z',[],'i',[],'c',[]);

tic;
for i = 1:nFrames
    frames(i) = hw.getFrame();
    %frames(i).i = fillInternalHolesMM(frames(i).i);
    
    if (tempEveryFrame)
        [temp.ldd,temp.mc,temp.ma,temp.tSense,temp.vSense]=hw.getLddTemperature;
        temps(i) = temp;
    end
    
    times(i) = toc;
    
    if (delay ~= 0)
        pause(delay);
    end
    
    if (verbose && (tempEveryFrame || delay ~= 0))
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
    if (tempEveryFrame)
        frames(i).lddTemp = temps(i).ldd;
        frames(i).temp = temps(i);
    end
    frames(i).time = times(i);
end

if (~tempEveryFrame)
    frames(1).temp = initTemp;
    frames(1).lddTemp = initTemp.ldd;
    [temp.ldd,temp.mc,temp.ma,temp.tSense,temp.vSense]=hw.getLddTemperature;
    frames(end).temp = temp;
    frames(end).lddTemp = temp.ldd;
end

%{
fileName = sprintf('checkerSperical_%4.1fdeg_%s.mat', frames(1).lddTemp, datetime);
fileName = strrep(fileName, ':','');
fileName = strrep(fileName, ' ','_');
save(fileName, 'frames', 'regs');
%}

end

