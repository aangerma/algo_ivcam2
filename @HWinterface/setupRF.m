function [ ] = setupRF(obj)
%SETUPRF write relevant regs to enable range finder.
% rfScripts = 'C:\source\algo_ivcam2\@objinterface\rfScripts';
rfScripts = fullfile(fileparts(mfilename('fullpath')),'rfScripts');
% // tia/ldd
obj.cmd('dirtybitbypass');
obj.runScript(fullfile(rfScripts,'TIA_LDD_HWM_snabber.txt'));

obj.cmd('exec_table 142');
% // setup VAPD
obj.runScript(fullfile(rfScripts,'proj_if_unlock_groups.txt'));
obj.runScript(fullfile(rfScripts,'pmg_clocks_depth_an2G_hf1G_as125M_ia267M_al267M.txt'));
obj.runScript(fullfile(rfScripts,'proj_if_fov_lut_ram.txt'));
obj.runScript(fullfile(rfScripts,'proj_if_hor_loc_ram.txt'));
obj.runScript(fullfile(rfScripts,'proj_if_hor_gain_ram.txt'));
obj.runScript(fullfile(rfScripts,'proj_if_loc_scale.txt'));
obj.runScript(fullfile(rfScripts,'proj_if_ver_gain_ram.txt'));
obj.runScript(fullfile(rfScripts,'proj_if_ver_loc_ram.txt'));
obj.runScript(fullfile(rfScripts,'proj_if_cfg_p0.txt'));
obj.runScript(fullfile(rfScripts,'proj_if_cfg.txt'));
obj.runScript(fullfile(rfScripts,'ansync_cfg.txt'));
obj.runScript(fullfile(rfScripts,'algo_cfg.txt'));
obj.runScript(fullfile(rfScripts,'dcor_mem.txt'));
obj.runScript(fullfile(rfScripts,'code52_dec4.txt'));
obj.runScript(fullfile(rfScripts,'afe_apd_cfg.vga30.txt'));
obj.runScript(fullfile(rfScripts,'rf_system_start.txt'));
obj.runScript(fullfile(rfScripts,'top_open_afclk_from_afe.txt'));

pause(1);


end

