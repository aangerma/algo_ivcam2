function filterSimulator
    %{
set(findobj(0,'type','figure'),'closeRequestFcn','closereq');close all
    %}
    defL = {'','','','40','',''};
    defH = {'1166','1166','1000','','1000',''};
    defO = {'1','1','1','1','1','1'};
    
    h.f=figure('closeRequestFcn',@closeTidy,'units','pixels');
    h.Tc = 0.1;
    h.ftot = figure('visible','off','closeRequestFcn','');
    h.atot = axes('parent',h.ftot);
    
    h.fcor = figure('visible','off','closeRequestFcn','');
    h.acor = axes('parent',h.fcor);
    
    h.fdct = figure('visible','off','closeRequestFcn','');
    h.adct = axes('parent',h.fdct);
    
    h.N=6;
    clf(h.f);
     maximize(h.f);
     set(h.f,'units','pixels');
    pp = get(h.f,'position');
    p = [0 0 pp(3)/h.N-10 pp(4)/2];
    
    for i=1:h.N
        h.taggb(i) = uitabgroup('parent',h.f,'units','pixels','position',[pp(3)/h.N*(i-1) 0 p(3) p(4)],'SelectionChangedFcn',{@callback_graphUpdate,i});
        
        tab = uitab(h.taggb(i),'Title','Butterworth');
        strct.cL=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-50 50 20],'string',defL{i},'callback',{@callback_graphUpdate,i});
        strct.cH=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-75 50 20],'string',defH{i},'callback',{@callback_graphUpdate,i});
        strct.n=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-100 50 20],'string',defO{i},'callback',{@callback_graphUpdate,i});
        uicontrol('style','text','string','Cutoff L','parent',tab,'position',[5 p(4)-50 50 20])
        uicontrol('style','text','string','Cutoff H','parent',tab,'position',[5 p(4)-75 50 20])
        uicontrol('style','text','string','order   ','parent',tab,'position',[5 p(4)-100 50 20])
        strct.vis = uicontrol('style','checkbox','string','visible','parent',tab,'position',[p(3)-125 p(4)-100 100 20],'value',1,'callback',{@callback_graphUpdate,i});
        strct.abs = uicontrol('style','checkbox','string','apply ABS before filter','parent',tab,'position',[p(3)-125 p(4)-120 100 20],'value',0,'callback',{@callback_graphUpdate,i});uicontrol('style','text','string','Mhz','parent',tab,'position',[120 p(4)-50 30 20])
        uicontrol('style','text','string','Mhz','parent',tab,'position',[120 p(4)-75 30 20])
        strct.a1=axes('parent',tab,'units','pixels','position',[50 50 p(3)-60 p(4)-175]);
        set(tab,'userdata',strct);
        
        
        tab = uitab(h.taggb(i),'Title','Cheby I');
        strct.cL=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-50 50 20],'string',defL{i},'callback',{@callback_graphUpdate,i});
        strct.cH=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-75 50 20],'string',defH{i},'callback',{@callback_graphUpdate,i});
        strct.rP=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[225 p(4)-50 50 20],'string','3','callback',{@callback_graphUpdate,i});
        strct.n=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-100 50 20],'string',defO{i},'callback',{@callback_graphUpdate,i});
        uicontrol('style','text','string','Cutoff L','parent',tab,'position',[5 p(4)-50 50 20])
        uicontrol('style','text','string','Cutoff H','parent',tab,'position',[5 p(4)-75 50 20])
        uicontrol('style','text','string','Ripple pass','parent',tab,'position',[160 p(4)-50 60 20])
        uicontrol('style','text','string','order   ','parent',tab,'position',[5 p(4)-100 50 20])
        strct.vis = uicontrol('style','checkbox','string','visible','parent',tab,'position',[p(3)-125 p(4)-100 100 20],'value',1,'callback',{@callback_graphUpdate,i});
        strct.abs = uicontrol('style','checkbox','string','apply ABS before filter','parent',tab,'position',[p(3)-125 p(4)-120 100 20],'value',0,'callback',{@callback_graphUpdate,i});uicontrol('style','text','string','Mhz','parent',tab,'position',[120 p(4)-50 30 20])
        uicontrol('style','text','string','Mhz','parent',tab,'position',[120 p(4)-75 30 20])
        uicontrol('style','text','string','db ','parent',tab,'position',[275 p(4)-50 30 20])
        strct.a1=axes('parent',tab,'units','pixels','position',[50 50 p(3)-60 p(4)-175]);
        set(tab,'userdata',strct);
        
        tab = uitab(h.taggb(i),'Title','Cheby II');
        strct.cL=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-50 50 20],'string',defL{i},'callback',{@callback_graphUpdate,i});
        strct.cH=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-75 50 20],'string',defH{i},'callback',{@callback_graphUpdate,i});
        strct.rS=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[225 p(4)-50 50 20],'string','30','callback',{@callback_graphUpdate,i});
        strct.n=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-100 50 20],'string',defO{i},'callback',{@callback_graphUpdate,i});
        uicontrol('style','text','string','Cutoff L','parent',tab,'position',[5 p(4)-50 50 20])
        uicontrol('style','text','string','Cutoff H','parent',tab,'position',[5 p(4)-75 50 20])
        uicontrol('style','text','string','Ripple stop','parent',tab,'position',[160 p(4)-50 60 20])
        uicontrol('style','text','string','order   ','parent',tab,'position',[5 p(4)-100 50 20])
        strct.vis = uicontrol('style','checkbox','string','visible','parent',tab,'position',[p(3)-125 p(4)-100 100 20],'value',1,'callback',{@callback_graphUpdate,i});
        strct.abs = uicontrol('style','checkbox','string','apply ABS before filter','parent',tab,'position',[p(3)-125 p(4)-120 100 20],'value',0,'callback',{@callback_graphUpdate,i});
        uicontrol('style','text','string','Mhz','parent',tab,'position',[120 p(4)-50 30 20])
        uicontrol('style','text','string','Mhz','parent',tab,'position',[120 p(4)-75 30 20])
        uicontrol('style','text','string','db ','parent',tab,'position',[275 p(4)-50 30 20])
        strct.a1=axes('parent',tab,'units','pixels','position',[50 50 p(3)-60 p(4)-175]);
        set(tab,'userdata',strct);
        
        tab = uitab(h.taggb(i),'Title','Eliptical');
        strct.cL=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-50 50 20],'string',defL{i},'callback',{@callback_graphUpdate,i});
        strct.cH=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-75 50 20],'string',defH{i},'callback',{@callback_graphUpdate,i});
        strct.rP=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[225 p(4)-50 50 20],'string','3','callback',{@callback_graphUpdate,i});
        strct.rS=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[225 p(4)-75 50 20],'string','50','callback',{@callback_graphUpdate,i});
        strct.n=uicontrol('style','edit','backgroundcolor','w','parent',tab,'position',[70 p(4)-100 50 20],'string',defO{i},'callback',{@callback_graphUpdate,i});
        uicontrol('style','text','string','Cutoff L','parent',tab,'position',[5 p(4)-50  50 20])
        uicontrol('style','text','string','Cutoff H','parent',tab,'position',[5 p(4)-75  50 20])
        uicontrol('style','text','string','Ripple pass','parent',tab,'position',[160 p(4)-50 60 20])
        uicontrol('style','text','string','Ripple stop','parent',tab,'position',[160 p(4)-75 60 20])
        uicontrol('style','text','string','order   ','parent',tab,'position',[5 p(4)-100 50 20])
        strct.vis = uicontrol('style','checkbox','string','visible','parent',tab,'position',[p(3)-125 p(4)-100 100 20],'value',1,'callback',{@callback_graphUpdate,i});
        strct.abs = uicontrol('style','checkbox','string','apply ABS before filter','parent',tab,'position',[p(3)-125 p(4)-120 100 20],'value',0,'callback',{@callback_graphUpdate,i});
        uicontrol('style','text','string','Mhz','parent',tab,'position',[120 p(4)-50  30 20])
        uicontrol('style','text','string','Mhz','parent',tab,'position',[120 p(4)-75  30 20])
        uicontrol('style','text','string','db ','parent',tab,'position',[275 p(4)-50 30 20])
        uicontrol('style','text','string','db','parent',tab,'position',[275 p(4)-75 30 20])
        strct.a1=axes('parent',tab,'units','pixels','position',[50 50 p(3)-60 p(4)-175]);
        set(tab,'userdata',strct);
        
        
        
        
        
        %     h.b(i)=b;
        
    end
    h.aa1=axes('parent',h.f,'units','pixels','position',[50         pp(4)/2+40 pp(3)/2-60 pp(4)/2-110]);
    h.aa2=axes('parent',h.f,'units','pixels','position',[50+pp(3)/2 pp(4)/2+40 pp(3)/2-60 pp(4)/2-110]);
    
    hToolbar = findall(h.f,'tag','FigureToolBar');
    
    uipushtool(hToolbar,'cdata',letter2icon('T'),'clickedcallback',{@inverseVisibility,h.ftot},'tooltipstring','Clear');
    uipushtool(hToolbar,'cdata',letter2icon('C'),'clickedcallback',{@inverseVisibility,h.fcor},'tooltipstring','Clear');
    uipushtool(hToolbar,'cdata',letter2icon('F'),'clickedcallback',{@inverseVisibility,h.fdct},'tooltipstring','Clear');
    
    guidata(h.f,h);
    for i=1:h.N
        callback_graphUpdate(h.f,[],i);
    end
end


function closeTidy(varargin)
    try
        h = guidata(varargin{1});
        set(h.ftot,'closeRequestFcn','closereq');
        set(h.fcor,'closeRequestFcn','closereq');
        set(h.fdct,'closeRequestFcn','closereq');
        set(h.f,'closeRequestFcn','closereq');
        close([h.ftot h.fcor h.fdct h.f]);
    catch
    end
end

function callback_graphUpdate(varargin)
    
    h = guidata(varargin{1});
    
    b = h.taggb(varargin{3}).SelectedTab.UserData;
    
    axes(b.a1);
    cla;
    
    [bp,ap]=abFromTab(h.taggb(varargin{3}).SelectedTab,h.Tc);
    col = lines(h.N+1);
    
    if(~isnan(bp))
        [H,f]=freqz_(bp,ap,2^10,1/h.Tc);
        
        loglog(f,abs(H),'linewidth',3,'color',col( varargin{3}+1,:));
        
    end
    grid on
    xlabel('Frequency (GHz) ')
    ylabel('Magnitude Response');
    callback_updateMainAxes(h)
end


function inverseVisibility(varargin)
    h = guidata(varargin{1});
    figH = varargin{3};
    
    v = get(figH,'visible');
    if(strcmpi(v,'off'))
        set(figH,'visible','on');
        
    else
        set(figH,'visible','off');
    end
    callback_updateMainAxes(h)
    if(strcmpi(get(figH,'visible'),'on'))
        figure(figH);
    end
end

function callback_updateMainAxes(h)
    NN=32;
    fc = 1/h.Tc;
%     tx =double(Codes.propCode(128,1));
    tx =double(Codes.propCode(26,1));
    txT = 1;
    
    zoomPlotNsec = 64;
    
    
    t=(0:length(tx)*fc*txT*NN-1)/fc;
    
    txsig = repmat(vec(repmat(tx,[1 txT*fc])'),NN,1)';
    rxsig = txsig;
    n = round(length(rxsig)/4);
    rxsig(n*1+1:n*2)=rxsig(n*1+1:n*2)/100;
    rxsig(n*3+1:n*4)=rxsig(n*3+1:n*4)/100;
    
    v = nan(h.N+1,length(t));
    v(1,:) = rxsig;
    btot=1;
    atot=1;
    for i=1:h.N
        [bp,ap]=abFromTab(h.taggb(i).SelectedTab,h.Tc);
        if(all(~isnan(bp)))
            vi = v(i,:);
            if(h.taggb(i).SelectedTab.UserData.abs.Value)
                vi = abs(vi);
            end
            v(i+1,:) = filter(bp,ap,vi);
            
            btot = conv(btot,bp);
            atot = conv(atot,ap);
        else
            v(i+1,:)=vi;
        end
    end
    for i=1:h.N
        [bp,~]=abFromTab(h.taggb(i).SelectedTab,h.Tc);
        if(any(isnan(bp)) || h.taggb(i).SelectedTab.UserData.vis.Value==0)
            v(i+1,:)=nan;
        end
    end
    axes(h.aa1);
    colormap(lines(h.N+1));
    plot(t,v);
    axis tight
    ylim(h.aa1,ylim(h.aa1)*1.2);
    
    axes(h.aa2);
    indx = length(t):-1:find(t>t(end)-zoomPlotNsec,1);
    plot(t(indx)-t(indx(end)),v(:,indx));
    colormap(lines(h.N+1));
    axis tight
    ylim(h.aa2,ylim(h.aa2)*1.2);
       
    
    [H,f]=freqz_(btot,atot,2^10,1/h.Tc);
    loglog(f,abs(H),'linewidth',3,'color','k','parent',h.atot);
    grid on
    xlabel('Frequency (GHz) ')
    ylabel('Magnitude Response');
    
%     ker = Utils.binarySeq(0:h.Tc:length(tx)*txT-h.Tc,tx,txT)*2-1;
%     c = conv2(v,fliplr(ker(:)'),'valid');
%     ct = 0:h.Tc:h.Tc*(size(c,2)-1);
%     xlyl = get(h.acor,{'xlim','ylim'});
%     plot(ct,c,'parent',h.acor);
%     if(~isequal([xlyl{1} xlyl{2}],[0 1 0 1]))
%         set(h.acor,{'xlim','ylim'},xlyl);
%     end
%     
    
    V = fft(v');
    ft = linspace(0,1/h.Tc,size(V,1));
    fn = 1:floor(size(V,1)/2);
    xlyl = get(h.adct,{'xlim','ylim'});
    plot(ft(fn),abs(V(fn,:)),'parent',h.adct)
    if(~isequal([xlyl{1} xlyl{2}],[0 1 0 1]))
        set(h.adct,{'xlim','ylim'},xlyl);
    end
    
    
end

function [bp,ap]=abFromTab(tab,Tc)
    t = tab.Title;
    b = tab.UserData;
    switch(t)
        case 'Butterworth'
            [bp,ap]=abFromB_butter(b,Tc);
        case 'Eliptical'
            [bp,ap]=abFromB_ellip(b,Tc);
        case 'Cheby I'
            [bp,ap]=abFromB_cheby1(b,Tc);
        case 'Cheby II'
            [bp,ap]=abFromB_cheby2(b,Tc);
    end
end

function [bp,ap]=abFromB_cheby2(b,Tc)
    bp = nan;
    ap = nan;
    N = str2double(get(b.n,'string'));
    if(isnan(N))
        return;
    end
    fL = str2double(get(b.cL,'string'))*1e-3*Tc*2;
    fH = str2double(get(b.cH,'string'))*1e-3*Tc*2;
    rS = str2double(get(b.rS,'string'));
    if(isnan(fL) && isnan(fH))
        return;
    elseif(~isnan(fL) && isnan(fH))
        [bp,ap]=cheby2(N,rS,fL,'high');
    elseif(isnan(fL) && ~isnan(fH))
        [bp,ap]=cheby2(N,rS,fH,'low');
    else
        if(fL>=fH)
            return;
        else
            [bp,ap]=cheby2(N,rS,[fL fH]);
        end
    end
end

function [bp,ap]=abFromB_cheby1(b,Tc)
    bp = nan;
    ap = nan;
    N = str2double(get(b.n,'string'));
    if(isnan(N))
        return;
    end
    fL = str2double(get(b.cL,'string'))*1e-3*Tc*2;
    fH = str2double(get(b.cH,'string'))*1e-3*Tc*2;
    rP = str2double(get(b.rP,'string'));
    if(isnan(fL) && isnan(fH))
        return;
    elseif(~isnan(fL) && isnan(fH))
        [bp,ap]=cheby1(N,rP,fL,'high');
    elseif(isnan(fL) && ~isnan(fH))
        [bp,ap]=cheby1(N,rP,fH,'low');
    else
        if(fL>=fH)
            return;
        else
            [bp,ap]=cheby1(N,rP,[fL fH]);
        end
    end
end

function [bp,ap]=abFromB_ellip(b,Tc)
    bp = nan;
    ap = nan;
    N = str2double(get(b.n,'string'));
    if(isnan(N))
        return;
    end
    fL = str2double(get(b.cL,'string'))*1e-3*Tc*2;
    fH = str2double(get(b.cH,'string'))*1e-3*Tc*2;
    rP = str2double(get(b.rP,'string'));
    rS = str2double(get(b.rS,'string'));
    if(isnan(fL) && isnan(fH))
        return;
    elseif(~isnan(fL) && isnan(fH))
        [bp,ap]=ellip(N,rP,rS,fL,'high');
    elseif(isnan(fL) && ~isnan(fH))
        [bp,ap]=ellip(N,rP,rS,fH,'low');
    else
        if(fL>=fH)
            return;
        else
            [bp,ap]=ellip(N,rP,rS,[fL fH]);
        end
    end
end

function [bp,ap]=abFromB_butter(b,Tc)
    bp = nan;
    ap = nan;
    N = str2double(get(b.n,'string'));
    if(isnan(N))
        return;
    end
    fL = str2double(get(b.cL,'string'))*1e-3*Tc*2;
    fH = str2double(get(b.cH,'string'))*1e-3*Tc*2;
    if(isnan(fL) && isnan(fH))
        return;
    elseif(~isnan(fL) && isnan(fH))
        [bp,ap]=butter(N,fL,'high');
    elseif(isnan(fL) && ~isnan(fH))
        [bp,ap]=butter(N,fH,'low');
    else
        if(fL>=fH)
            return;
        else
            [bp,ap]=butter(N,[fL fH]);
        end
    end
end