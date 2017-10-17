%inputs
baseDir = '\\invcam322\ohad\data\lidar\EXP\20160105\ir';
tblXYfn = '\\invcam322\ohad\data\lidar\memsTables\2015-12-22\60Hz\memsTable.mat';
vslowFs = 125; %MHz

rawfns = [dirFiles(baseDir,'*.bin');dirFiles(baseDir,'*.h5')];
for i=1:length(rawfns)
    fn_in = rawfns{i};
    [pathstr,name,~] = fileparts(fn_in);
    if( exist([pathstr,'\',name,'.png'],'file'))
        continue;
    end
    
    
    
    try
        [vscope,vscopeFs,t,mirTicks] = slowChanEvalRawData('fn_in',fn_in);
        raw_data.vscope = vscope;
        raw_data.vscopeFs = vscopeFs;
        raw_data.t = t;
        raw_data.mirTicks = mirTicks;
        Tc = 1/raw_data.vscopeFs; %nsec
        
        
        % before filter
        N = 3; %order
        rS = 60; %ripple stop - dB
        fL = 475; %MHz
        fH =  525; %MHz
        wL = fL*1e-3*Tc*2;
        wH = fH*1e-3*Tc*2;
        % [bpb,apb]=butter(N,rS,wL,'high'); %Lcutoff - HP
        % [bpb,apb]=butter(N,rS,wH,'low'); %Hcutoff - LP
        [bpB,apB]=cheby2(N,rS,[wL wH]); %BP
        
        
        % abs
        is_abs = true;
        
        
        % after filter
        N = 3; %order
        rS = 60; %ripple stop - dB
        % fL = 60; %MHz
        fH =  50; %MHz
        % wL = fL*1e-3*Tc*2;
        wH = fH*1e-3*Tc*2; 
        %  [bpa,apa]=butter(N,rS,wL,'high'); %Lcutoff - HP
        [bpA,apA]=cheby2(N,rS,wH,'low'); %Hcutoff - LP
        % [bpa,apa]=cheby2(N,rS,[wL wH]); %BP
        
        
        
        vg = slowChanEval('tblXYfn',tblXYfn,'fn_in',fn_in,'raw_data',raw_data,'abs',is_abs,'vslowFs',vslowFs,'filter_before',[bpB;apB],'filter_after',[bpA;apA],'verbose',false);
        
        figure(34)
        TH = prctile(vg(:),[5 95]);
        img4save = max(0,min(1,(vg-TH(1))/diff(TH)))*255;
        imagesc(img4save);
        colormap(gray(256));
        axis image
        drawnow;
        
        imwrite(uint8(img4save),[pathstr,'\',name,'.png'],'Alpha', double(~isnan(img4save)));
        display(['saved ' pathstr,'\',name,'.png' ]);
    catch ex
        display(['ERROR in ' name ':' ex.message])
        continue;
    end
    
    
end