function [dt,pzr,indLocs]=readScopeLOS(fn,mode)
%% Scope Config. & Readout
% Chan1: VSync
% Chan2: pzr{1} (SA)
% Chan3: pzr{2} (PA)
% Chan4: pzr{3} (FA)
% D0: HSync
% 1st Hsync on Rise of HSync (D0) / T=0

pzr={};
% Normalize Sync, Fix. Polarities, Remove Sensors Offset
dtOut = 1/125e6;


switch(mode)
    case 'poc4l_mc_msync'
    

        [t0,dtS,v]=io.POC.readScopeHDF5data(fn,2);
        Scope_Data.Ts=dtS;
        Scope_Data.time=(0:dtS:(length(v)-1)*dtS)';
        Scope_Data.Msync_P=v;
        [t0,dtS,v]=io.POC.readScopeHDF5data(fn,3);
        Scope_Data.Msync_N=v;
        Scope_LVDS_Offset=0.2;
        Scope_Data.LVDS=Scope_Data.Msync_P-Scope_Data.Msync_N+Scope_LVDS_Offset;
       [t0,dtS,v]=io.POC.readScopeHDF5data(fn,1);
       decimationFactor = round(dtOut/dtS);
        vsync=v(1:decimationFactor:end); % rescaling
        
        dt=dtS*decimationFactor; % 125e6
       
%         MC_DAC_SF=0.9; % V
%         MC_DAC_Offset=-0.45; %V
        
       [t0,dtS,v]=io.POC.readScopeHDF5data(fn,4);
%        Scope_Data.SA_LOS_DAC=(v(1:10:end)+MC_DAC_Offset)/MC_DAC_SF;
% PARSE
        
        [xx,yy]=lvdsStreamParser(Scope_Data.LVDS,dtS,dt);
        
        pzr{1}=xx';%(xx/2^12*1.2-0.6)';
        pzr{2}=yy';%(yy/2^12*1.2-0.6)';
         
%          pzr{1} = AngX_Res; % SA_LOS
%         pzr{2} = AngY_Res; %FA_LOS
%         pzr{3} = Scope_Data.SA_LOS_DAC; %NA
        pzr{3} = zeros(size(pzr{2}));
%      plot(tt,yy)
        vsync_=(schmittTrig(vsync,0.79/2,1.03/2))';
        %build hsync
        hsyncref=pzr{1};
        mpzr2=mean(hsyncref);
        
        fmir=1/(mean(diff(find(diff(vsync_)==1)))*dt);
        [b,a]=butter(3,fmir*dt*2/2);
        hsyncref=filtfilt(b,a,hsyncref);
        c=round(crossing([],hsyncref,mpzr2));
        c(diff(c)<100)=[];%adajcent points(if any)
        
        if(hsyncref(c(1)-1)<mpzr2)%first edge always falling WHY ???
            c(1)=[];
        end
                
        c=c(1:length(c)+mod(length(c),2)-1);%odd number - last is always fall
        % figure,plot(hsyncref),hold on,plot(c,0,'ro')
        
        cfall=c(1:2:end);
        crise=c(2:2:end);
        hsync_=zeros(size(vsync_));
        for i=1:length(crise)
            hbeg = minind(hsyncref(cfall(i):crise(i)))+cfall(i)-1;
            hend = maxind(hsyncref(crise(i):cfall(i+1)))+crise(i)-1;
            hsync_(hbeg:hend)=1;
        end
    case 'poc4l'
        chfns = dirFiles(fileparts(fn),'*.trc');
        v=cellfun(@(x) io.POC.readLeCroyBinaryWaveform(x),chfns,'uni',0);
        dt=v{1}.desc.Ts;
        n = min(cellfun(@(x) length(x.x),v));
        v = cellfun(@(x) x.y(1:n),v,'uni',0);
        
        pzr{1} = v{2};
        pzr{2} = v{3};
        pzr{3} = v{4};
        vsync = v{1};
        
        
        
        vsync_=(schmittTrig(vsync,0.79,1.03))';
        %build hsync
        mpzr2=mean(pzr{2});
        
        fmir=1/(mean(diff(find(diff(vsync_)==1)))*dt);
        
        hsyncref=(pzr{1}+pzr{2})/2;
        
        [b,a]=butter(3,fmir*dt*2/2);
        hsyncref=filtfilt(b,a,hsyncref);
        c=round(crossing([],hsyncref,mpzr2));
        
        c(diff(c)<100)=[];%adajcent points(if any)
        
        if(hsyncref(c(1)-1)<mpzr2)%first edge always falling
            c(1)=[];
        end
        c=c(1:length(c)+mod(length(c),2)-1);%odd number - last is always fall
        cfall=c(1:2:end);
        crise=c(2:2:end);
        hsync_=zeros(size(vsync_));
        for i=1:length(crise)
            hbeg = minind(pzr{2}(cfall(i):crise(i)))+cfall(i)-1;
            hend = maxind(pzr{2}(crise(i):cfall(i+1)))+crise(i)-1;
            hsync_(hbeg:hend)=1;
        end
        
    case {'poc4'}
        [~,dt,pzr{1}]=io.POC.readScopeHDF5data(fn,2);
        [~,~,pzr{2}]=io.POC.readScopeHDF5data(fn,3);
        [~,~,pzr{3}]=io.POC.readScopeHDF5data(fn,4);
        pzr = cellfun(@(x) x-mean(x),pzr,'uni',0);
        [~,~,vsync]=io.POC.readScopeHDF5data(fn,1);
        [~,~,hsync]=io.POC.readScopeHDF5data(fn,5);
        hsync_=nbm(hsync(1,:));
        vsync_=(schmittTrig(vsync,0.79,1.03))';
    case 'poc3'
        [~,dt,pzr{1}]=io.POC.readScopeHDF5data(fn,2);
        [~,~,pzr{2}]=io.POC.readScopeHDF5data(fn,3);
        [~,~,pzr{3}]=io.POC.readScopeHDF5data(fn,4);
        pzr = cellfun(@(x) x-mean(x),pzr,'uni',0);
        FACTOR=100;
        pzr=cellfun(@(x) x(1:FACTOR:end),pzr,'uni',0);
        dt=dt*FACTOR;
        
        hsync_=zeros(size(pzr{1}));
        
        i1 = maxind(pzr{1});
        i0 = minind(pzr{1}(1:i1));
        hsync_(i0:i1)=1;
        vsync_=hsync_;
        
end




vsync_locs = round(crossing([],vsync_,0.5));


%move zero crossing to scan crossing
crossingDelay = round(mean(diff(vsync_locs))/2);
vsync_locs = vsync_locs+crossingDelay;
vsync_locs(vsync_locs>length(vsync_))=[];


if(sum(abs(diff(hsync_)))>100)%very noise H-sync? replace with single frame
    hsync_ = hsync_*0;hsync_(2:vsync_locs(end)-1)=1;
end

%if starting in high
if(hsync_(1)>0)
    hsync_(find(hsync_==0,1):end)=0;
end
%if ending in high
if(hsync_(end)>0)
    hsync_(find(hsync_==0,1,'last'):end)=0;
end

hsync_rise = find(hsync_(1:end-1)<hsync_(2:end));
hsync_fall = find(hsync_(1:end-1)>hsync_(2:end))+1;
nFrames = min(length(hsync_rise),length(hsync_fall));


indLocs = cell(nFrames,1);
for i=1:nFrames
    i0=find(vsync_locs>=hsync_rise(i),1);
    i1=find(vsync_locs>=hsync_fall(i),1);
    indLocs{i}=vsync_locs(i0:i1);
end


end


function y=nbm(x)
mm=minmax(x);
y=(x-mm(1))/diff(mm);
end


%SCHMITT TRIGGER
%SchmittTrig(x,tL,tH,PF)
function [y] = schmittTrig(x,tL,tH)


limit=0;

N=length(x);

y=zeros(size(x));



for i=1:N
    
    
    if ( limit ==0)
        
        y(i)=0;
        
    elseif (limit == 1)
        
        y(i)=1;
        
    end
    
    
    if (x(i)<=tL)
        limit=0;
        y(i)=0;
        
    elseif( x(i)>= tH)
        limit=1;
        y(i)=1;
        
    end
    
    
end


end