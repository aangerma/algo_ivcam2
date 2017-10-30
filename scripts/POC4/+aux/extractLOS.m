function angxyQ=extractLOS(pzr,params,dt,verbose)
% Extract LOS
% V.8.1.1
% Date: 5/4/17

% LOS_Filt - LOS & Sync Data
% LOS_Raw - Raw Data no filtered
% LOS_Cut - Chunked frames
% LOS_SingleFrame - arrange FrameNum data in chunks of Vsync

%  [LOS_Cut,LOS_Raw,LOS_Filt]=Extract_LOS('Poc4_RealData_06.h5')

% Fn          - Filename (H5 format)
% FrameNum    - choose frame number to be cut
% Flavor      - 'A' or 'B'

% Updates
% 9/1/17
% schmitt triggering added to LOS_Cut Vsync
% 10/1/17
% Filters changed (order & runtime)
% 20/1/17
% Porcino flavor B compatabilty
% Filters mod. (SA PZR's)
% 22/1/17
% Cut frames with respect to recorded Hsyncs ! (and not peak detector)
switch(lower(params.dataMode))
    case {'poc4','poc41d','poc4l'}

pzr{1}=pzr{1}*params.pzrPolarity(1);
pzr{2}=pzr{2}*params.pzrPolarity(2);
pzr{3}=pzr{3}*params.pzrPolarity(3);



PA_Angle=(pzr{2}-pzr{1})/2;
PA_Angle_filtered = runFilter(PA_Angle,params.pa,dt);

SA_LOS=(pzr{1}+pzr{2})/2;
FA_LOS=params.pa2faGain*PA_Angle_filtered+pzr{3};

SA_LOS_filterd = runFilter(SA_LOS,params.sa,dt);
FA_LOS_filterd = runFilter(FA_LOS,params.fa,dt);
case 'poc4l_mc_msync'
        
        
        SA_LOS_filterd = pzr{1};
        FA_LOS_filterd = pzr{2};
end
if(~isfield(params.fa,'scale'))
    params.fa.scale = 2/diff(minmax(FA_LOS_filterd));
    if(verbose),fprintff('\nparams.fa.scale: %f\n',params.fa.scale);end
end
if(~isfield(params.sa,'scale'))
    params.sa.scale = 2/diff(minmax(SA_LOS_filterd));
    if(verbose),fprintff('params.sa.scale: %f\n',params.sa.scale);end
end
if(~isfield(params.fa,'offset'))
    params.fa.offset = mean(minmax(FA_LOS_filterd));
    if(verbose),fprintff('params.fa.offset: %f\n',params.fa.offset);end
end
if(~isfield(params.sa,'offset'))
    params.sa.offset = mean(minmax(SA_LOS_filterd));
    if(verbose),fprintff('params.sa.offset: %f\n',params.sa.offset);end
end
FA_LOS_filterd = (FA_LOS_filterd - params.fa.offset)*params.fa.scale;
SA_LOS_filterd = (SA_LOS_filterd - params.sa.offset)*params.sa.scale;

% angxyQ = int16([SA_LOS_filterd/max(abs(SA_LOS_filterd))*(2^11-1)...
%                 FA_LOS_filterd/max(abs(FA_LOS_filterd))*(2^11-1)])';
angxyQ = [SA_LOS_filterd  FA_LOS_filterd]';
qVal=(2^11-1);
angxyQ = max(-qVal,min(qVal,angxyQ*qVal));

end


function vout=runFilter(vin,p,dt)
fs2=0.5/dt;
vout=vin;
for i=1:size(p.filt,1)
    f = p.filt(i,:);
    if(f(1)==0 && f(2)==0)
        continue;
    elseif(f(1)==0)%lowpass
        [b,a]=butter(2,f(2)/fs2,'low');
    elseif(f(2)==0)%highpass
        [b,a]=butter(2,f(1)/fs2,'high');
    elseif(f(1)>f(2))%band-stop
        [b,a]=butter(1,fliplr(f)/fs2,'stop');
    else%band pass
        [b,a]=butter(1,f/fs2);
    end
    vout=aux.FiltFiltM(b,a,vout);
end
vout=circshift(vout,p.D);
end