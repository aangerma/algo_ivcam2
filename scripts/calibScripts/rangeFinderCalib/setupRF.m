clear


rfScripts = 'C:\source\algo_ivcam2\@HWinterface\rfScripts';
% rfScripts = '\\tmund-mobl1\c$\source\algo_ivcam2\@HWinterface\rfScripts';
hw = HWinterface();
hw.cmd('mwd a00e09e4 a00e09e8 0 ');
hw.cmd('mwd a00e09e8 a00e09ec 0 ');
hw.cmd('mwd a00e09ec a00e09f0 0 ');
% // tia/ldd
hw.runScript(fullfile(rfScripts,'TIA_LDD_HWM_snabber.txt'));

hw.cmd('exec_table 142');
% // setup VAPD
hw.runScript(fullfile(rfScripts,'proj_if_unlock_groups.txt'));
hw.runScript(fullfile(rfScripts,'pmg_clocks_depth_an2G_hf1G_as125M_ia267M_al267M.txt'));
hw.runScript(fullfile(rfScripts,'proj_if_fov_lut_ram.txt'));
hw.runScript(fullfile(rfScripts,'proj_if_hor_loc_ram.txt'));
hw.runScript(fullfile(rfScripts,'proj_if_hor_gain_ram.txt'));
hw.runScript(fullfile(rfScripts,'proj_if_loc_scale.txt'));
hw.runScript(fullfile(rfScripts,'proj_if_ver_gain_ram.txt'));
hw.runScript(fullfile(rfScripts,'proj_if_ver_loc_ram.txt'));
hw.runScript(fullfile(rfScripts,'proj_if_cfg_p0.txt'));
hw.runScript(fullfile(rfScripts,'proj_if_cfg.txt'));
hw.runScript(fullfile(rfScripts,'ansync_cfg.txt'));
hw.runScript(fullfile(rfScripts,'algo_cfg.txt'));
hw.cmd('mwd a0020af8 A0020AFC fff0ffff')
hw.cmd('mwd a0020b00 A0020B04 ffff12ff')
hw.runScript(fullfile(rfScripts,'dcor_mem.txt'));
hw.runScript(fullfile(rfScripts,'afe_apd_cfg.vga30.txt'));
hw.runScript(fullfile(rfScripts,'rf_system_start.txt'));
hw.runScript(fullfile(rfScripts,'top_open_afclk_from_afe.txt'));
pause(1);



hw.cmd('mwd a00e05e8 a00e05ec 1'); % RegsRangeFlush
pause(5);

hw.cmd('mrd a00e05f4 a00e05f8');
hw.cmd('mrd a00e05f4 a00e05f8');
a = hw.cmd('mrd a00e05f4 a00e05f8');

if ~strcmp(a(end-7:end),'00000000')
    for i = 1:10000
       v =  hw.cmd('mrd a00e05f4 a00e05f8');
       v = v(end-7:end);
       Z(i) = hex2dec(v(end-3:end));
       C(i) = hex2dec(v(end-4:end-4));
       I(i) = hex2dec(v(end-6:end-5));
    end
    tabplot;
    plot(Z);
    tabplot;
    plot(C);
    tabplot;
    plot(I);

else
    fprintf('all zero');
end



% TODO: 
% Change baseline 
% Understand and change regs.DIGG.gengRangeFinderLUT
% collect cma
% cma = hw.readCMAinRF(1);
% tabplot; plot(cma)
