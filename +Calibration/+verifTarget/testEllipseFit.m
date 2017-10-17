t = linspace(0,1,100);
t = t(1:end-1);
r = 3;
x = r*cos(2*pi*t);
y = r*sin(2*pi*t);

% x = x+30;
% res = Calibration.calibTarget.ellipsefit([x;y]);


xx = x;
yy = y;

%scale
yy = yy*5;

%noise
noiseFactor = 0.2;
xx = xx+noiseFactor*randn(size(xx));
yy = yy+noiseFactor*randn(size(yy));



%rotate
theta = 40;
rot = [...
    cosd(theta)  -sind(theta);
    sind(theta) cosd(theta)];

rotxy = rot*[xx;yy];

xx = rotxy(1,:);
yy = rotxy(2,:);



% plot
figure(214321);clf;
% plot(x,y,'.b');
hold on;
% text(x,y, num2cell(1:length(x)));
plot(xx,yy,'*r');
% text(xx+0.02,yy+0.01, num2cell(1:length(xx)));

axis equal;

%ellipse fit
res = Calibration.calibTarget.ellipsefit(xx,yy);

% ell = inv(res.T)*[x;y;ones(size(x))];
circ = res.T*[xx;yy;ones(size(xx))];

% plot(ell(1,:),ell(2,:),'*g');
plot(circ(1,:),circ(2,:),'*k');
% text(circ(1,:)+0.01,circ(2,:)+0.01, num2cell(1:length(x)));








%%
    nsamples = 1000;
    samples = (1:nsamples)/nsamples;
    x = cos(2*pi*samples);
    y = sin(2*pi*samples);
    
    [U,S,V] = svd(res.Q);
    Snew = [1/sqrt(S(1,1)) 0; 0 1/sqrt(S(2,2))];
    xyEllipse = U*Snew*[x;y];
        plot(xyEllipse(1,:),xyEllipse(2,:),'*g');

    
