hw = HWinterface();
hw.setPresetControlState(2);
%%
frame = hw.getFrame(10,false);
% hw.shutDownLaser;

frame = hw.getFrame(10,false);
frameDefault = hw.getFrame;
hwCommand = 'mwd a00e1600 a00e1604 00000100 // JFILgrad1thrMaxDiag';
%%
setOnlyOneGrad1Th(hw, hwCommand);
frame = hw.getFrame(10,false);
frameConfig = hw.getFrame;
%%
hw.cmd('mwd a00e15f0 a00e15f4 00000001 // JFILgrad1bypass');
hw.cmd('mwd a00e166c a00e1670 00000001 // JFILgrad2bypass');
hw.shadowUpdate();
frame = hw.getFrame(10,false);
frameNoGrad = hw.getFrame;
%%
hw.stopStream;

%%
figure;
maxClim = max([frameDefault.z(:)./4;frameConfig.z(:)./4;frameNoGrad.z(:)./4])+10;
subplot(1,3,1); imagesc(imrotate(frameDefault.z./4,180),[0,maxClim]); title('Today''s grad filter config');impixelinfo;
subplot(1,3,2); imagesc(imrotate(frameConfig.z./4,180),[0,maxClim]); title('New grad filter config');impixelinfo;
subplot(1,3,3); imagesc(imrotate(frameNoGrad.z./4,180),[0,maxClim]); title('Both grad filters are bypassed');impixelinfo;
linkaxes; 

