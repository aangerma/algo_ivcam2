function [txDelay] = txDelayfromRTD(darr)

opt.maxIter=10000;
opt.OutputFcn=[];
opt.TolFun = 1e-6;
opt.TolX = 1e-6;
opt.Display='none';
for i = 1:numel(darr)
    % Get rpt
    rtd = darr(i).rpt(:,:,1);
    
    
end
[gx,gy] = meshgrid(-6:6,-4:4);
gx = gx*darr(i).sz;gy = gy*darr(i).sz;

v0single = [0 0 600 0];
optVars = repmat(v0single,numel(darr),1);
optVars = [4500;optVars(:)]';


fr = @(v) errfun(darr,gx,gy,v);
vL = repmat([-1000,-1000,0,-pi],numel(darr),1);
vL = [4000;vL(:)];
vH = repmat([ 1000, 1000,500,pi],numel(darr),1);
vH = [6000;vH(:)];
[vbest,e]=fminsearchbnd(fr,optVars,vL,vH,opt);
txDelay = vbest(1);

end
function [e] = errfun(darr,gx,gy,optVars)
    txd = optVars(1);
    v = reshape(optVars(2:end)',[],4);
    e = 0;
    for i = 1:numel(darr)
       e = e +  sqrt(mean(mean(((gx-30*cos(v(i,4))-v(i,1)).^2+(gy-v(i,2)).^2+(-30*sin(v(i,4))+v(i,3)).^2-(0.5*(darr(i).rpt(:,:,1)-txd)).^2).^2)));
    end
end
% 4983,30.2047
% 4990,55.5
