function rmm = dtnsec2rmm(dtnsec)

%C = 299.792458; %vacum%mm/nsec
C = 299.702547; %air%mm/nsec


rmm = dtnsec*C/2 ;%mm
end