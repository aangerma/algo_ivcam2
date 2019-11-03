function [vers, subVersion] = AlgoThermalCalibToolVersion()
    global gProjID;
    if ~isempty(gProjID) && gProjID == iv2Proj.L520
        vers = 3.01;
        subVersion = 0;
    else
        vers = 4.17;
        subVersion = 0;
    end
end