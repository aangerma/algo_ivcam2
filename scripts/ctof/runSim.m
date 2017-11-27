function [ mes,grndtrth ] = runSim( params )
%%




%%
[mdl.v,mdl.f,~,colData]=stlread(params.modelFn);
 mdl.v=(mdl.v-(max(mdl.v)+min(mdl.v))/2)./max((max(mdl.v)-min(mdl.v)))*1200;
 mdl.v(:,3)=1000-mdl.v(:,3);
mdl.a = mean(colData,2)/31;
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
[d,a]=Simulator.aux.raytrace2d(mdl.f,mdl.v,mdl.a,r,params.sensor.tMat);
d=RaytracerMEX(single(reshape(mdl.v(vec(mdl.f'),:),9,[])),uint8(255*repmat(mdl.a',3,1)),single(r'));
%quantize distances according to system_dt
dS = round(d/(C()*params.system_dt))*C()*params.system_dt;
rtd = reshape(sum(dS,2),[h w]);
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

tau = rtd/C(); %nsec
delayIndx = tau/params.system_dt;
grndtrth.rtdS = rtd;


%% create tx signal


%% create rx signal, before sampling
nScenarios = length(params.scenario.data);
mes = cell(nScenarios,1);

for s=1:nScenarios
    [hh,ww,nPatterns ]=size(params.scenario.data{s}.pat);
    assert(ww==w & hh==h);
    
    mes{s} = zeros(nPatterns,1);%measurments amtrix
    
    t0=0;
    t1=max(tau(~isinf(tau)))+(1+length(params.scenario.data{s}.txmod))*params.scenario.dt;
    ts = t0:params.system_dt:t1;
    
    txsignal = interp1((0:length(params.scenario.data{s}.txmod)-1)*params.scenario.dt,params.scenario.data{s}.txmod,ts,'previous',0);
    txsignal = txsignal*params.prjector.power/(hh*ww);
    rwmod = interp1((0:length(params.scenario.data{s}.rxmod)-1)*params.scenario.dt,params.scenario.data{s}.rxmod,ts,'previous',0);
    chanAttenuation = grndtrth.a.*min(1,params.sensor.collectionArea./(4*pi*reshape(dS(:,2),[hh ww]).^2));
    normPats = params.scenario.data{s}.pat.*chanAttenuation;
    for p=1:nPatterns
        thisPat = normPats(:,:,p);
        
        rxsignal=delaySum(txsignal,delayIndx,thisPat);
        %{
                rxsignal = zeros(size(txsignal));
                for i=1:w*h
                    if(isinf(delayIndx(i)))%no back echo
                        continue;
                    end
                    rayrx = [zeros(1,delayIndx(i)) txsignal(1:end-delayIndx(i))];%apply delay
        
                    rayrx = rayrx*thisPat(i);%projector attenuation
                     rayrx = rayrx*grndtrth.a(i); %apply attenuation tue to albedo
                    %      rayrx = rayrx/(1+grndtrth.rtdS(i)/1e3)^2;%distance attenuation
                    %     rayrx = rayrx/pi;%specularity factor
                    rxsignal= rxsignal+rayrx;
                end
        %}

        
        mes{s}(p)=rxsignal*rwmod'*params.system_dt;%sum(rxsignal(rwmod==1))*params.system_dt;
        if(params.verbose>0)
            fprintf('Generating measurment (%d,%d)/(%d,%d)\n',p,s,nPatterns,nScenarios);
        end
        if(params.verbose>2)
            ah=plot(ts,txsignal,ts,rxsignal,ts,rwmod*max(txsignal),'linewidth',2);
            set(ah(1),'linewidth',4);
            
            xlabel('time[nsec]');
            legend('TX','RX','RXwindow');
            drawnow;
        end
    end
    if(isempty(params.sensor.sampler.v0))
        params.sensor.sampler.v0 = min([mes{:}]);
    end
    if(isempty(params.sensor.sampler.v1))
        params.sensor.sampler.v0 = max([mes{:}]);
    end

    
end
if(params.verbose>0)
    mm = cellfun(@(x) x',mes,'uni',0);
    mm = minmax([mm{:}]);
    fprintf('pre sampler range: [%g : %g]\n',mm);
end
 for s=1:length(mes)
     mes{s} = round((mes{s}-params.sensor.sampler.v0)./(params.sensor.sampler.v1-params.sensor.sampler.v0)*(2^params.sensor.sampler.nbits-1));
 end


