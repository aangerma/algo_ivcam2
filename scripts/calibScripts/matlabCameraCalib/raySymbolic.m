syms angx angy zenx zeny;

rotx = [cosd(angx) 0 sind(angx); 0         1         0; -sind(angx) 0 cosd(angx)];
roty = [1 0          0; 0 cosd(angy) -sind(angy); 0 sind(angy)  cosd(angy)];

