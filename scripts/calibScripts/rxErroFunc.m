function e = rxErroFunc(x,p)
ir_delay  =[    ];
ir_delay(1,:)=[0         x(1)];
ir_delay(2,:)=[x(2)     x(3)];
ir_delay(3,:)=[x(2)*2    0];
ir_delay(4,:)=[4094     0];
ir_delay(5,:)=[4095     0];



x=linspace(0,4096,65);

lut=single(interp1(ir_delay(:,1),ir_delay(:,2),x,'spline'));

% plot(lut);
lut4regs = lut/1024;
 fprintf('DESTrxPWRpd_%03d h%08x\n',[0:64;typecast(lut4regs,'uint32')])
p.regs.DEST.rxPWRpd=lut4regs;
txmode = bitand(bitshift(p.pipeFlags,-1),uint8(3))+1;
rtdImg = Pipe.DEST.rtdDelays(p.rtdImg,p.regs,p.iImgRAW,txmode);
[z,~,x,y]=Pipe.DEST.rtd2depth(rtdImg,p.regs);

%%
[~,d,inliers] = planeFitRansac(x,y,z,p.msk);
e=rms(d(inliers));
% imagesc(d)

