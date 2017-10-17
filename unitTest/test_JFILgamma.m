I = io.readBin('\\INVCAM322\ohad\data\lidar\EXP\regression\horse\0500_horse\0500_horse.bini');

% fw = Firmware();
% regs = fw.getRegs();
% luts = fw.getLuts();
% [dImgFil,iImgFil, cImgFil] = Pipe.JFIL.JFIL(pipeOutData,regs,luts);
jStreamIn.ir = uint16(I/(2^8-1)*(2^12-1));



%% LUT in->out
regs.JFIL.gamma = linspace(0,1,65)*(2^8-1);
jStream = Pipe.JFIL.gamma( jStreamIn, regs, [],'gamma', [] );
f = figure;
subplot(131);imagesc(double(jStreamIn.ir)/(2^12-1)*(2^8-1),[0,2^8-1]);colormap gray;title('old');
subplot(132);imagesc(jStream.ir,[0,2^8-1]);title('after gamma');colormap gray
subplot(133);imagesc(abs(double(jStream.ir)-double(jStreamIn.ir)/(2^12-1)*(2^8-1)));title('diff');colormap gray
subplotTitle('LUT equal')

%% LUT brighter
regs.JFIL.gamma =  sqrt(linspace(0,1,65))*(2^8-1);
jStream = Pipe.JFIL.gamma( jStreamIn, regs, [],'gamma', [] );
f = figure;
subplot(131);imagesc(double(jStreamIn.ir)/(2^12-1)*(2^8-1),[0,2^8-1]);colormap gray;title('old');
subplot(132);imagesc(jStream.ir,[0,2^8-1]);title('after gamma');colormap gray
subplot(133);imagesc(abs(double(jStream.ir)-double(jStreamIn.ir)/(2^12-1)*(2^8-1)));title('diff');colormap gray
subplotTitle('LUT brighter')

%% LUT darker
regs.JFIL.gamma =  (linspace(0,1,65).^2)*(2^8-1);
jStream = Pipe.JFIL.gamma( jStreamIn, regs, [],'gamma', [] );
f = figure;
subplot(131);imagesc(double(jStreamIn.ir)/(2^12-1)*(2^8-1),[0,2^8-1]);colormap gray;title('old');
subplot(132);imagesc(jStream.ir,[0,2^8-1]);title('after gamma');colormap gray
subplot(133);imagesc(abs(double(jStream.ir)-double(jStreamIn.ir)/(2^12-1)*(2^8-1)));title('diff');colormap gray
subplotTitle('LUT darker')