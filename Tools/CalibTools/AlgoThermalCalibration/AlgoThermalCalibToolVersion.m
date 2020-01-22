function [vers, subVersion] = AlgoThermalCalibToolVersion()
    global gProjID;
    if ~isempty(gProjID) && gProjID == iv2Proj.L520
        vers = 3.01;
        subVersion = 0;
    else
        vers = 4.35;
        subVersion = 0;
    end
end