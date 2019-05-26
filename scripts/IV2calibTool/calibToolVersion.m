function [vers,subVersion,versionBytes] = calibToolVersion()
    vers = 2.03;
    subVersion = 0;
    versionBytes = uint8([floor(vers), rem(vers,1)*100,subVersion,0]);
end