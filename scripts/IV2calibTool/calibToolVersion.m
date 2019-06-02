function [vers,subVersion,versionBytes] = calibToolVersion()
    vers = 2.04;
    subVersion = 1;
    versionBytes = uint8([floor(vers), rem(vers,1)*100,subVersion,0]);
end