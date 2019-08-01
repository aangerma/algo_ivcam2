%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% WARNING: EXTREME NON-SAFE PROCEDURE!!!
%%% Carrying out the following set of commands turns on laser while mirror is at rest!!!
%%% Must operate safety procedures (protective glasses, curtain, warning sign etc.) before carrying out these commands!!!
%%% When done, plug out camera immediately!!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % // Voltage supply
% hw.cmd('mwd fffc2000 fffc2004 2000')
% hw.cmd('mwd fffc2004 fffc2008 2000')
% hw.cmd('mwd fffe18a4 fffe18a8 13000')
% 
% % // Laser Driver configuration for 'all the time' projection
% hw.cmd('iwb e2 01 01 04') % // Taking LD out of StandBy
% hw.cmd('iwb e2 02 01 FE') % // Force LD output to '1' (ignore HFM), + pulse width control 1E
% hw.cmd('iwb e2 03 01 13') % // Force MOD_DAC from register + Snubber value 13, Soft TX enable
% hw.cmd('iwb e2 05 01 ff') % // Max Bias set to FF
% hw.cmd('iwb e2 06 01 30') % // Bias value set to 30
% hw.cmd('iwb e2 08 01 90') % // Modulation DAC value set to 90
% hw.cmd('iwb e2 09 01 FF') % // Max modulation set to FF
% hw.cmd('iwb e2 0a 01 08') % // Modulation Ref set to 08
% 
% % // Projector Clock Enable
% hw.cmd('mwd a001000c a0010010 ff613373') % //[m_regmodel.pmg_pmg.RegsPmgClkEn] TYPE_REG
% hw.cmd('mwd a0010100 a0010104 10000000') % //[m_regmodel.pmg_pmg.RegsPmgDepthEn] TYPE_REG
% hw.cmd('mwd a00c0100 a00c0104 00000001') % //[m_regmodel.pmg_dpt_pmg.RegsPmgDptEn] TYPE_REG
% 
% % // Force LD_ON to '1'
% hw.cmd('mwd a00504d0 a00504d4 3000000') % // Force LD_On to '1'
% hw.cmd('iwb e2 02 01 c0') % TURN CW ON LDD
