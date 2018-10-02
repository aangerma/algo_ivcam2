function vals = readConfInput(hw,nAvg,inputId)
r=Calibration.RegState(hw);
% r.add('JFILbypass$'        ,true    );
w1 = int8(zeros(1,4)); w1(inputId) = 4;
r.add('DESTconfw1'        ,w1    );
r.add('DESTconfv'        ,int8([0,0,127])    );
r.add('DESTconfactIn'        ,int16([0,255])    );
r.add('DESTconfq'        ,int8([1,0])    );
r.add('DESTconfactOt'        ,int16([-2,255])    );
r.add('DESTconfw2'        ,int8([0,0,0,0])    );
% r.add('DESTconfIRbitshift'        ,int8(6)    );
r.set();
% regs.DEST.confw1 = w1;
% regs.DEST.confv = int8([0,0,127]);
% regs.DEST.confactIn = int16([0,255]);
% regs.DEST.confq = int8([1,0]);
% regs.DEST.confactOt = int16([-2,255]);
% regs.DEST.confw2 = int8([0,0,0,0]);
% regs.DEST.confIRbitshift = int8(6);

vals = zeros([size(hw.getFrame().i),nAvg]);
pause(0.3);
for i = 1:nAvg
    vals(:,:,i) = hw.getFrame().c;
end
vals(vals==0) = nan;
vals = mean(vals,3,'omitnan');
r.reset();
end