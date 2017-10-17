function projectorCalibration
fw = Firmware();
ivs = io.readIVS('D:\ohad\data\lidar\EXP\20160915\test06.ivs');
fw.setRegs('D:\ohad\data\lidar\EXP\20160915\Config.csv');
fw.setRegs('D:\ohad\data\lidar\EXP\20160915\calib.csv');



%%
%  fw.setRegs('FRMWgaurdBandH',1.1);
%  fw.setRegs('FRMWgaurdBandV',0.8);
%  fw.setRegs('GNRLxoffset',22);
  fw.setRegs('FRMWxoffset',22);
%   fw.setRegs('FRMWxfov',50);
regs = fw.getRegs();
luts = fw.getLuts();


xy=Pipe.DIGG.GENG(ivs.xy(1,:),ivs.xy(2,:),regs,luts);
xy = double(xy);
xy(1,:)=xy(1,:)/4;

inroi = all([xy>0;bsxfun(@lt,xy,[regs.GNRL.imgHsize;regs.GNRL.imgVsize])]);
plot(xy(1,:),xy(2,:),xy(1,inroi),xy(2,inroi));
% set(gca,'xlim',[0 regs.GNRL.imgHsize],'ylim',[0 regs.GNRL.imgVsize]);
axis equal
end
