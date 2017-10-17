function [vg,vslow,vslowFs,funcdata] = slowChanEval(varargin)

%%%%%%%%%%%%%%%%%%%
%varargin parser:
%%%%%%%%%%%%%%%%%%%

inp = inputParser;

inp.addOptional('tblXYfn','\\invcam322\ohad\data\lidar\memsTables\2015-12-22\60Hz\memsTable.mat');
inp.addOptional('fn_in','\\invcam322\ohad\data\lidar\EXP\20151028\025_31dBm_diff_horse_lensless.h5');
inp.addOptional('raw_data',[]);
inp.addOptional('verbose',true );
inp.addOptional('code_length',26 );

inp.addOptional('filterFunction',@(v) v ); 
inp.addOptional('vslowFs',125); %MHz
inp.addOptional('syncenforce','none');
inp.addOptional('w',640);
inp.addOptional('h',480);
parse(inp,varargin{:});
arg = inp.Results;



vscope = arg.raw_data.vscope;
vscopeFs = arg.raw_data.vscopeFs;
t = (0:length(vscope)-1)/vscopeFs;
mirTicks = arg.raw_data.mirTicks;


irSyncfn = [arg.fn_in '_irSYNC.txt'];
pixPhaseDelay = 0;



w = arg.w;
h = arg.h;


vF = arg.filterFunction(vscope,vscopeFs);




%% sampling

vslowFs = arg.vslowFs/1000;

tS = 0:1/vslowFs:t(end);
if(vscopeFs==vslowFs)
    vslow=vF;
else
    vslow = interp1(0:1/vscopeFs:t(end),vF,0:1/vslowFs:t(end));
end

%% Digital filtering
% IIR notch - we have parasitic freq in the freq of the codeLength - 26/32/64...

bw = 0.02/(vslowFs/2);

w0 = (1/arg.code_length)/(vslowFs/2);
[b,a] = iirnotch(w0,bw);
vslow = filter(b,a,vslow);

w0 = (vslowFs/2-mod(1/arg.code_length*2,vslowFs/2))/(vslowFs/2);
[b,a] = iirnotch(w0,bw);
vslow = filter(b,a,vslow);

w0 = (vslowFs/2-mod(1/arg.code_length*3,vslowFs/2))/(vslowFs/2);
[b,a] = iirnotch(w0,bw);
vslow = filter(b,a,vslow);



%% calibrate the XY table according to the sync delay

load(arg.tblXYfn,'tblXY');
tblXY;%#ok
tblXY = circshift(conv2(tblXY([1:end 1:99],:),ones(100,1)/100,'valid'),50);
tblXY = tblXY(1:size(tblXY,1)/2,:);
clkN_ = interp1(mirTicks,1:length(mirTicks),tS,'linear','extrap')+pixPhaseDelay;
save2file=false;
if(~exist(irSyncfn,'file'))
    
    mSyncDelay = Calibration.aux.mSyncer(vslow,clkN_,tblXY);
    save2file = true;
else
    mSyncDelay = fileReadNumeric(irSyncfn);
    switch(arg.syncenforce)
        case 'coarse'
            mSyncDelay = Calibration.aux.mSyncer(vslow,clkN_,tblXY);
            save2file = true;
        case 'fine';
            mSyncDelay = Calibration.aux.mSyncer(vslow,clkN_,tblXY,mSyncDelay);
            save2file=true;
    end
end
if(save2file)
    fid = fopen(irSyncfn,'w');
    fprintf(fid,'%d',mSyncDelay);
    fclose(fid);
end
tblXY = circshift(tblXY,[round(-mSyncDelay) 0]);
tblXY = bsxfun(@times,tblXY([1:end 1],:)/8,[w h]./[640 480])+1;

%% get time,x & y of each data point
funcdata.t0=t(1);
funcdata.mrt=mirTicks;
funcdata.tbl=tblXY;
funcdata.pixPhaseDelay=pixPhaseDelay;

sxy = xy4t(tS,funcdata);
%take only the samples that are inside the wXh window
goodIndx =~( sxy(:,1)<1 | sxy(:,1)>w | sxy(:,2)<1 | sxy(:,2)>h | any(isnan(sxy),2)) ;
sxyGood = sxy(goodIndx,:);
vS_good = vslow(goodIndx);


%% sinus to pixels matrix
%(x,y) -> ind
ind = sub2ind([h,w],round(sxyGood(:,2)),round(sxyGood(:,1)));
gind=accumarray(ind,vS_good,[h*w,1],@mean,nan);
vg = reshape(gind,[h w]);

%what to do with nan
msk = isnan(vg);
[by,bx] = find(msk);
bind = sub2ind([h,w],by,bx);
vgM = zeros(h,w);
for iii=bind'
    [yi,xi]=ind2sub([h w],iii);
    yr=max(1,yi-1):min(h,yi+1);
    xr=max(1,xi-1):min(w,xi+1);
    rr = vg(yr,xr);
    vgM(iii)=mean(rr(~isnan(rr(:))));
end
vg(msk)=vgM(msk);


%% plot the outcome

if(arg.verbose)
    figure(1000)
    imagesc(vg,prctile(vg(:),[1 99]));
    colorbar;
    colormap(gray(256));
    axis image
end


end



