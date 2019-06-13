function [vers,subVersion,versionBytes] = calibToolVersion()
    global gProjID;
    if ~isempty(gProjID) && gProjID == iv2Proj.L520
        vers = 16.04;
    else
        vers = 2.04;
    end
    subVersion = 1;
    versionBytes = uint8([floor(vers), rem(vers,1)*100,subVersion,0]);
end