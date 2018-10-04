function params_struct = create_params_struct(sort_bypass_mode, JFIL_sharpS, ...
                                    JFIL_sharpR, RAST_sharpS, RAST_sharpR)
% this function generate a struct that contain
% the values of the registers (related to mos optimization)
% for recording with JFIL enabled

    params_struct.sort_bypass_mode = sort_bypass_mode;
    params_struct.JFIL_sharpS = JFIL_sharpS;
    params_struct.JFIL_sharpR = JFIL_sharpR;   
    params_struct.RAST_sharpS = RAST_sharpS;
    params_struct.RAST_sharpR = RAST_sharpR;   
end