function [ mesQ,grndtrth ] = runSimple( params )
%%




%%
if(ischar(params.model))
    [mdl.v,mdl.f,~,colData]=stlread(params.model);
    mdl.v=(mdl.v-(max(mdl.v)+min(mdl.v))/2)./max((max(mdl.v)-min(mdl.v)))*1200;
    mdl.v(:,3)=1000-mdl.v(:,3);
    mdl.a = mean(colData,2)/31;
elseif(isstruct(params.model))
    mdl=params.model;
else
    error('Unknonwn input model');
end
if(all(mdl.a==0))
rng(0);
mdl.a=rand(size(mdl.a))*0.5+.5;
end
h = params.prjector.res(1);
w = params.prjector.res(2);
[yg,xg]=ndgrid(linspace(-1,1,h)/params.prjector.kMat(2,2),linspace(-1,1,w)/params.prjector.kMat(1,1));
r = [xg(:),yg(:),yg(:)*0+1];
r = r./sqrt(sum(r.^2,2));

%  mdl.v=mdl.v./sqrt(sum(mdl.v.^2,2))*mean(sqrt(sum(mdl.v.^2,2))); %!!!!!!!!!!!!!!!!!!!!!SPERIPHY

%%
% [d,a]=Simulator.aux.raytrace2d(mdl.f,mdl.v,mdl.a,r,params.sensor.tMat);
d=u.RaytracerMEX(single(reshape(mdl.v(vec(mdl.f'),:)',9,[])),single(repmat(mdl.a',3,1)),single(r'),single(params.sensor.tMat));
d= double(d);
a=mean(d(3:5,:))';
d=d(1:2,:)';
%quantize distances according to system_dt

grndtrth.a = reshape(a,[h w]);
if(params.verbose>1)
    %%
    rd = r.*d(:,1);
    trisurf(mdl.f,mdl.v(:,1),mdl.v(:,2),mdl.v(:,3),mdl.a,'edgecolor','none')
    plotCam(params.prjector.rMat,zeros(3,1),100,[.75 0 0 ],params.prjector.kMat);
    line(rd(:,1)'.*[0;1],rd(:,2)'.*[0;1],rd(:,3)'.*[0;1],'color','r')
    axis equal
    xlabel('x');
    ylabel('y');
    zlabel('z');
end

%% prequizites


grndtrth.rtdS = zeros(size(grndtrth.a));


%% create tx signal


%% create rx signal, before sampling
nScenarios = length(params.scenario.data);
mes = cell(nScenarios,1);


%fill on scenario #2
p=params.scenario.data{2}.pat;
p=reshape(p,numel(grndtrth.a),[]);
p=p./sum(p);
mes{2}=grndtrth.a(:)'*p;

mesQ = mes;
% cell(nScenarios,1);
% nrm = @(s) round(min(1,max(0,(s-params.sensor.sampler.v0)/(params.sensor.sampler.v1-params.sensor.sampler.v0)))*(2^params.sensor.sampler.nbits-1));
%  for s=1:length(mes)
%      mesQ{s} = uint64(nrm(mes{s}))';
%  end


