% saveDFZInput
%   Saves slim workspace inside DFZ_Calib_Calc_int relevant for calling calibDFZ

temp_d = d;
d = rmfield(d, {'i', 'z', 'pts', 'ptsCropped'});
save('calibDFZ_input_slim.mat', 'd', 'trainImages', 'regs', 'calibParams', 'fprintff', 'runParams')
d = temp_d;
clear temp_d
