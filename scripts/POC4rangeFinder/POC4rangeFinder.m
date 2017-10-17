function POC4rangeFinder
%{
mcc -m POC4rangeFinder.m -d \\ger\ec\proj\ha\perc\SA_3DCam\Ohad\share\POC4RangeFinder\ -a ..\..\+Pipe\tables\* -a .\*
%}
sourModes = {'FullFlowWithHardware'
    'OnlyGPLABFrames'
    'SplittedFrames'
    'SplittedFramesSimulation'
    'Simulation'
    'RecordFullFlowWithHardware'
    'RecordOnlyGPLABFrames'
    'RecordSplittedFrames'
    'RecordSplittedFramesSimulation'
    'RecordSimulation'
    'RecordBinaryFullFlowWithHardware'
    'RecordBinaryOnlyGPLABFrames'
    'RecordBinarySplittedFrames'
    'RecordBinarySplittedFramesSimulation'
    'RecordBinarySimulation'
    'RecordForExerciser'
    };

fprintf('Pipe version: %s\n',Pipe.version());
W=500;
H=220;
h.f = figure('name','POC4 rangeFinder','numbertitle','off','toolbar','none','menubar','none','units','pixels','position',[0 0 W H]);
centerfig(h.f);
clf(h.f);
lh=22;
panel_gplab_N=7.5;
panel_gplab=uipanel('units','pixels','position',[10 H-lh*8 480 lh*panel_gplab_N],'title','params','parent',h.f);
uicontrol('style','text','units','pixels','position',[10 10+lh*5 120 20],'String','Source mode','horizontalalignment','left','parent',panel_gplab);
uicontrol('style','text','units','pixels','position',[10 10+lh*4 120 20],'String','Auto skew','horizontalalignment','left','parent',panel_gplab);
uicontrol('style','text','units','pixels','position',[10 10+lh*3 120 20],'String','GPlab type','horizontalalignment','left','parent',panel_gplab);
uicontrol('style','text','units','pixels','position',[10 10+lh*2 120 20],'String','In directory','horizontalalignment','left','parent',panel_gplab);
uicontrol('style','text','units','pixels','position',[10 10+lh*1 120 20],'String','Record out directory','horizontalalignment','left','parent',panel_gplab);

h.sourceMode     = uicontrol('style','popupmenu','units','pixels','position',[140 10+lh*5 150 20],'String',sourModes,'horizontalalignment','left','parent',panel_gplab);
h.useAutoSkew = uicontrol('style','checkbox','units','pixels','position',[140 10+lh*4 120 20],'value',0,'horizontalalignment','left','parent',panel_gplab);
h.gpType      = uicontrol('style','popupmenu','units','pixels','position',[140 10+lh*3 120 20],'String',{'USB','PCIexpress'},'horizontalalignment','left','parent',panel_gplab);
h.inDir      = uicontrol('style','edit','units','pixels','position',[140 10+lh*2 320 20],'String','c:\temp\Frames_rec_constant\Frames\','horizontalalignment','left','parent',panel_gplab);
h.outRecDir   = uicontrol('style','edit','units','pixels','position',[140 10+lh*1 320 20],'String','c:/temp/rec2peaks/','horizontalalignment','left','parent',panel_gplab);

uicontrol('style','text','units','pixels','position',[10 10+lh*0 120 20],'String','# frame av','horizontalalignment','left','parent',panel_gplab);
h.nAveraging = uicontrol('style','edit','units','pixels','position',[140 10+lh*0 50 20],'String','1','horizontalalignment','left','parent',panel_gplab);




uicontrol('style','pushbutton','units','pixels','position',[10 10 W-20 lh],'String','START','parent',h.f,'callback',@callback_run);

guidata(h.f,h);

end
%%
function callback_run(varargin)
hObj=guidata(varargin{1});


gpMode = hObj.sourceMode.Value-1;
gpType = hObj.gpType.Value-1;
doAutoSkew = hObj.useAutoSkew.Value;
% propDist=single(str2double(hObj.propDistance.String));%str2double(inputdlg('offset range'));
nFrmeAv=str2double(hObj.nAveraging.String);
inDir = hObj.inDir.String;
recOutDir = hObj.outRecDir.String;




%%
fprintf('Starting Firmware...');
configFn = fullfile(inDir,'config.csv');
if(~exist(configFn,'file'))
    error(['no file:' configFn]);
end

fw = Firmware();
fw.setRegs(configFn);
regs = fw.get();

codeLength = double(regs.GNRL.codeLength);
sampleRate= double(regs.GNRL.sampleRate);
tmplLength = codeLength*sampleRate;
%%

fprintf('Starting GPlab...');
gplab=GPlab(gpMode,gpType,doAutoSkew,tmplLength,inDir,recOutDir); %hardware
gplab.start();
[ivs.fast, ivs.slow,~,ivs.flags]=gplab.getFrame();
gplab.stop();
n = length(ivs.slow)/(ceil(double(sampleRate*codeLength)/64))*nFrmeAv;
w = ceil(sqrt(n)*.5)*2;
h = floor(n/w*.5)*2;

%%
% fprintf('Starting Firmware(%dx%d)...',w,h);
% 
% fw = Firmware();
% fprintf('done\n');

newregs.FRMW.xres = uint16(w);
newregs.FRMW.yres = uint16(h);
newregs.MTLB.xyRasterInput=true;
newregs.JFIL.bypass=true;
% newregs.FRMW.coarseSampleRate = uint8(2);
newregs.DIGG.notchBypass=true;
newregs.DEST.baseline=single(0);
newregs.RAST.biltSharpnessS=uint8(6);
newregs.RAST.biltSharpnessR=uint8(6);
% %  newregs.RAST.biltBypass=true;
% k = zeros(1,128);
% k(1:codeLength)=Codes.propCode(codeLength,1);
% newregs.FRMW.txCode = uint32(sum(bsxfun(@times,reshape(uint32(k),32,4),uint32(2.^(0:31)'))));
% newregs.DEST.txFRQpd = single([1 1 1]*propDist*2);
fw.setRegs(newregs,'POC4');
[regs,luts]= fw.get();

% fprintf('done\n');




%%


f = figure('Numbertitle','off','name','Range finder','toolbar','none','MenuBar','none');
maximize(f);
a = arrayfun(@(i) subplot(2,6,i),1:6,'uni',0);
% xy00 = get(a{1},'Position');
% xy11 = get(a{end},'Position');
hEditbox = uicontrol('units','normalized','position',[0 .1 1 0.4],'style','edit', 'max',5,'parent',f,'horizontalalignment','left','fontname','courier','fontSize',12);
cnt =1;
hGrabButton = uicontrol('units','normalized','position',[0 0 1 0.1],'style','toggleButton','parent',f,'string','GRAB');
%%

txt='';
txtHead = sprintf('%5s | %9s | %9s | %9s | %9s | %9s | %9s  | %9s | %9s  | %9s ',...
    '#','u(r)','s(r)','u(ir)','s(ir)','s(irR)','u(c)','range(r)','range(ir)','ser[%]');
txtHead = [txtHead char(10) '-'*ones(size(txtHead))];
% if(hObj.doJitter.Value==1)
%     ff=figure(8889);
%     hh(1) = subplot(1,2,1,'parent',ff);
%     hh(2) = subplot(1,2,2,'parent',ff);
%     t_acc=[];
%     r_acc=[];
%     f_acc=[];
% end
% nJitterPoints = 8;

% ker=(luts.DCOR.templates(256*64+(1:regs.GNRL.tmplLength)));
ker=vec(repmat(Utils.uint322bin(regs.FRMW.txCode,regs.GNRL.codeLength),1,regs.GNRL.sampleRate)');
% md = @(x) mod(x-1,length(ker))+1;
% riseLocs = find(diff(int8(ker))>0);
% fallLocs = find(diff(int8(ker))<0);



while(ishandle(f))
    %%
    fprintf('start...');
    [rImg,iImg,cImg,v,iSigRaw] = calcDistance(gplab,w,h,nFrmeAv,regs,luts);
    corr=Utils.correlator(uint8(v),ker);
    fprintf('display...');
    
    %%
    
    
    
    lims = prctile_(rImg(:),[5 95]);
    ind = (rImg>lims(1) & rImg<lims(2));
    rmu = mean(rImg(ind));
    rsig = std(rImg(ind));
    
    lims = prctile_(iImg(:),[5 95]);
    iind = (iImg>lims(1) & iImg<lims(2));
    imu = mean(iImg(iind));
    isig = std(iImg(iind));
    
    
    cmu = mean(cImg(iind));
    
    %     peakLoc = Pipe.DEST.detectPeaks(mean(corr,2),0);
    peakLoc = Pipe.DEST.detectPeaks(corr,0,true)-1;
    peakLoc = mean(peakLoc);
    if(isnan(peakLoc) ||isinf(peakLoc))
        peakLoc=0;
    end
            ser=round(nnz(bsxfun(@bitxor,v,circshift(ker>0,round(peakLoc)-1)))/numel(v)*100);
        i_minmax= diff(minmax(iImg(:)));
        r_minmax= diff(minmax(rImg(:)));
    %%
    if(~ishandle(f))
        break;
    end
    %% display
    imagesc(corr,'parent',a{1});
    axis(a{1},'tight');
    title(a{1},'CORRLETAION');
    grid(a{1},'on')
    axis(a{1},'square')
    
    
    imagesc(iImg,'parent',a{5});
    title(a{5},'IR');axis(a{5},'square')
    colorbar(a{5},'east');
    
    imagesc(rImg,'parent',a{4});
    colorbar(a{4},'east');
    title(a{4},'Depth');
    axis(a{4},'square');
    
    
    histogram(iImg(:)-imu,-20:20,'parent',a{3});
    grid(a{3},'on')
    grid(a{3},'minor')
    title(a{3},'HIST-IR')
    axis(a{3},'square');
    
    histogram(rImg(:)-rmu,-20:20,'parent',a{2});
    grid(a{2},'on')
    grid(a{2},'minor')
    title(a{2},'HIST-D')
    axis(a{2},'square');
    
    fftplot(ivs.slow(1:length(ivs.slow)-mod(length(ivs.slow),2)),0.125,'parent',a{6});
    axis(a{6},'tight');
    axis(a{6},'square');
    txtInc = sprintf('%5d   %9.3f   %9.3f   %9.3f   %9.3f   %9.3f   %9.3f   %9.3f   %9d   %9d   %9d',cnt,rmu,rsig,imu,isig,iSigRaw,cmu,r_minmax,i_minmax,ser);
    if(hGrabButton.Value==1)
        hGrabButton.Value=0;
        txtInc = [txtInc '    *']; %#ok
        fid = fopen('grabbed','a');
        fprintf(fid,'%s\n',sprintf('%f ',rImg(:)));
        fclose(fid);
    end
    
    cnt = cnt+1;
    txt = [txtInc char(10) txt];%#ok
    hEditbox.String = [txtHead char(10) txt];
    

    
%     if(hObj.doJitter.Value==1)
%         vmoved = circshift(v,-floor(peakLoc));
%         %     dximg=cat(3,vmoved,repmat(ker>0,1,size(v,2)),vmoved);
%         ximg = bsxfun(@bitxor,vmoved,ker>0);
%         r_delta=zeros(nJitterPoints*2,1);
%         f_delta=zeros(nJitterPoints*2,1);
%         nr = length(riseLocs)*size(v,2);
%         nf = length(fallLocs)*size(v,2);
%         
%          r_gb = zeros(length(riseLocs),size(ximg,2),nJitterPoints*2);
%         f_gb = zeros(length(fallLocs),size(ximg,2),nJitterPoints*2);
% 
%         for i=1:nJitterPoints*2
%             r_gb(:,:,i) = ~ximg(md(riseLocs+i-3),:);
%              f_gb(:,:,i) = ~ximg(md(fallLocs+i-3),:);
%         end
%          for i=1:nJitterPoints*2
%              is = iff(i<=nJitterPoints,i:nJitterPoints,nJitterPoints+1:i);
%              r_delta(i) =nnz(all(r_gb(:,:,is),3))/nr;
%              f_delta(i) =nnz(all(f_gb(:,:,is),3))/nf;
%         end
%         %r_delta(1) -  probability that jiteer was smaller than 4samples+delta
%         %r_delta(2) -  probability that jiteer was smaller than 3samples
%        delta = peakLoc-floor(peakLoc);
%        se = @(x,y) iff(x<y,x:y,x:-1:y);
%        t_jitter = [se(nJitterPoints-1,0)+delta -se(0,nJitterPoints-1)+(delta-1)]';
%     t_acc=[t_acc t_jitter]; %#ok
%     r_acc=[r_acc r_delta];%#ok
%     f_acc=[f_acc f_delta];%#ok
%        
%         plot(t_acc,r_acc,'.','parent',hh(1));
%          plot(t_acc,f_acc,'.','parent',hh(2));
%         fid = fopen('jitterPoints.txt','w');
%         fwrite(fid,mat2str([t_acc';r_acc';f_acc']));
%         fclose(fid);
%     end
    drawnow;
    fprintf('done\n');
end


end

function [rImg,iImg,cImg,v,irRAWstd] = calcDistance(gplab,w,h,nFrmeAv,regs,luts)

pcktsPerCode = double(regs.GNRL.tmplLength)/64;
assert(rem(pcktsPerCode,1)==0)
nReqPackets = w*h*pcktsPerCode;



gplab.start();
%for averaging, get N_FRAMES_AV frames
fprintf('get');
ivs.fast=logical([]);ivs.slow=[];ivs.flags=[];

for q=1:nFrmeAv
    fprintf('.');
    [f_, s_,~,l_]=gplab.getFrame();
    ivs.fast=[ivs.fast f_];
    ivs.slow=[ivs.slow s_];
    ivs.flags=[ivs.flags l_];
end

fprintf('stop...');
gplab.stop();

irRAWstd = std(double(ivs.slow));
nn = min (nReqPackets,length(ivs.slow));
nn = floor(nn/(w*h))*w*h;
[yy,xx]=ind2sub([h w],vec(repmat(1:w*h,nn/(w*h),1)));
ivsxy= int16([(xx-1)*4 yy-1]');


ivs.fast=ivs.fast(1:nn*64);
ivs.slow=ivs.slow(1:nn);

ivs.xy=ivsxy;

ivs.flags=zeros(size(ivs.slow),'uint8');
ivs.flags=bitset(ivs.flags,1); %ld_on
ivs.flags(1:pcktsPerCode:end)=bitset(ivs.flags(1:pcktsPerCode:end),2);%tx_code_start
ivs.flags=bitset(ivs.flags,3); %scan_dir

%add dummpy packets at the end
for i=1:3
    ivs.fast = [ivs.fast false(1,64)];
    ivs.slow(end+1)=0;
    ivs.flags(end+1)=0;
    ivs.xy(:,end+1)=[w*4;h]+1;
end



fprintf('Pipe...');
pipeOut=Pipe.hwpipe(ivs,regs,luts,Pipe.setDefaultMemoryLayout(),Logger(),[]);
rtd = pipeOut.rtdImg;
rImg = 0.5*(rtd.^2-regs.DEST.baseline.^2)./rtd;
iImg = double(pipeOut.iImgRAW);
cImg = double(pipeOut.cImgRAW);
v = buffer_(ivs.fast,double(regs.GNRL.tmplLength));
v = v(:,1:end-1);


end


