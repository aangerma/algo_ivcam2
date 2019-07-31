function [vers,subVersion,versionBytes] = calibToolVersion()
    global gProjID;
    if ~isempty(gProjID) && gProjID == iv2Proj.L520
        vers = 16.04;
        subVersion = 0;
    else
        vers = 3.05;
        subVersion = 0;
    end
    
    versionBytes = uint8([floor(vers), rem(vers,1)*100,subVersion,0]);
end