function [txregs  ] = setCode( hw,name,decRatio)
% fprintf('\nSetting code %s... ',name);
% switch name
%     case '64'
%         txregs.FRMW.txCode = uint32([hex2dec('6569656A'),hex2dec('959A6AA6'),0,0]);
%         txregs.GNRL.codeLength = uint8(64);
%     case '62'
%         txregs.FRMW.txCode = uint32([hex2dec('959AA9A5'),hex2dec('2A55A665'),0,0]);
%         txregs.GNRL.codeLength = uint8(62);
%     case '31x2'
%         txregs.FRMW.txCode = uint32([hex2dec('69B121C1'),hex2dec('3F2A33DD'),0,0]);
%         txregs.GNRL.codeLength = uint8(62);
%     case '52'
%         txregs.FRMW.txCode = uint32([hex2dec('69966665'),hex2dec('000A6AA9'),0,0]);
%         txregs.GNRL.codeLength = uint8(52);    
%     otherwise
%         error('Unknown code name: %s.',name);
% end
% if decRatio == 4 % Coarse dec ratio       
%     txregs.FRMW.coarseSampleRate = uint8(2);
% elseif decRatio == 8
%     txregs.FRMW.coarseSampleRate = uint8(1);
% end

hw.runPresetScript('maReset');
pause(0.1);
scriptfn = strcat('code',name,'_dec',num2str(decRatio),'.txt');
hw.runScript(scriptfn);
pause(0.1);
hw.runPresetScript('maRestart');
pause(0.1);
hw.cmd('mwd a00d01ec a00d01f0 00000001 // EXTLauxShadowUpdateFrame');
pause(0.1);

frame = hw.getFrame();
tabplot; subplot(1,2,1); imagesc(frame.z/8); subplot(1,2,2); imagesc(frame.i);
subplot(1,2,2); title(scriptfn(1:end-4));
fprintf('Done.\n');
end

