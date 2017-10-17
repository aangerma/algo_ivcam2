function vout = applySimFilter(vin,fs,filter_before,absV,filter_after)
    
    fs;%#ok
  
    
    vout = vin;
    
    %first filter
    filb = filter_before.bp;
    fila = filter_before.ap;
    if(~isnan(filb))
        vout = filter(filb,fila,vout);
    end
    
    %abs
    if(absV)
        vout = abs(vout);
    end
    
    %second filter
    filb = filter_after.bp;
    fila = filter_after.ap;
    
    if(~isnan(filb))
        vout = filter(filb,fila,vout);
    end
%     
%     N = 6;
%     Fcarrier = 1/26;
%     bw = 0.001/fs*2;
%     for i=1:N
%     [filb,fila]=iirnotch(Fcarrier/fs*2*i,bw);
%      vout = filter(filb,fila,vout);
%     end
    
end