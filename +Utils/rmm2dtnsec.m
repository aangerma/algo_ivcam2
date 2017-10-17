function dtnsec=rmm2dtnsec(rmm)
%C = 299792458; %vacum
C = 299702547; %air
dtnsec = rmm*1e-3*2/C *1e9 ;%nsec
end