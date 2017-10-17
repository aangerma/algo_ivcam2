


figure; hold on
for k=1:20
    t = linspace(0,20,10000);
    t = t + ceil(rand(size(t))*50);
    t = conv(t,ones(1,200)/200,'same');
    x = cos(t+(pi/10)*k);
    y = sin(t+(pi/10)*k);
    z =  linspace(0,20,10000);
    plot3(z,x,y);
end
box off; axis equal off



[tx,ker,c]=Codes.barker7; tx=tx(:); tx = tx';
figure; hold on
for k=1:20
    len = 10000; nt = imresize(tx,[1,len]);
    t = linspace(0,40,len);
    x = cos(t+(pi/10)*k);
    x = x + 4*nt;
    plot(t,x);
end
box off; axis equal off
