function [jStream] = geom(jStreamIn, regs, luts,instance, lgr,traceOutDir)%#ok
jStream = jStreamIn;
lgr.print2file('\t\t------- geom -------\n');

%% pre calc

if(~regs.JFIL.geomBypass)
    
    xnorInnerProduct = @(m,n) double(m)*double(n) + double(~m)*double(~n);
    [templateQuery,templateMdian,invalidationTemplate] =  loadTemplates();
    
    templateMdian = uint16(templateMdian);
    
    
    
    %% 5*5 patchs
    sz = size(jStream.conf);
    
    indx = Utils.indx2col(sz,[5 5]);
    
    patchValid = jStream.conf(indx)>regs.JFIL.geomConfThr;
    patchDepth = jStream.depth(indx);
    patchConf = jStream.conf(indx);
    
    
    
    %% find best tamplate
    tmpltCorr = xnorInnerProduct(patchValid',templateQuery);
    
    %no need to correlate all 64, only first 32. The rest is 25-the first
    assert(all(vec(tmpltCorr(:,1:32)==25-tmpltCorr(:,33:end))))
    
    
    [matchScore,matchTmplt] = max(tmpltCorr,[],2);
    matchTmplt = reshape(matchTmplt,sz);
    matchScore = reshape(matchScore,sz);
    
    
    %%
    
    dontTouch = matchScore<regs.JFIL.geomMinHits     | ...
	            jStream.conf>regs.JFIL.geomGoodConf  |...
				~regs.JFIL.geomTemplateEnable(matchTmplt);
    
    
    %invalidate
    updateMask =  ~dontTouch &  invalidationTemplate(matchTmplt) & jStream.conf>regs.JFIL.geomBadConf ;
    jStream.conf(updateMask) = regs.JFIL.geomBadConf;
    
    
    %validate - if  template flag is on
    
    updateMask = ~dontTouch & ~invalidationTemplate(matchTmplt);
    vdpth=templateMdian(:,matchTmplt(updateMask)).*patchDepth(:,updateMask);
    jStream.depth(updateMask)=myFastMedian(vdpth);
    vconf=uint8(templateMdian(:,matchTmplt(updateMask))).*patchConf(:,updateMask);
    jStream.conf(updateMask)=myFastMedian(vconf);
    
    
end

%% debug
if (isfield(jStream,'debug'))
    jStream.debug{end+1}={instance,jStream.depth,jStream.ir,jStream.conf};
end


Pipe.JFIL.checkStreamValidity(jStream,instance,false);


if(~isempty(traceOutDir) )
    Utils.buildTracer([dec2hexFast(jStream.ir,3) dec2hexFast(jStream.conf,1) dec2hexFast(jStream.depth,4)],['JFIL_' instance],traceOutDir);
end

lgr.print2file('\t\t----- end geom -----\n');
    
end
%

function y = myFastMedian(mat)
mat = sort(mat,1);
% number of valid element in each column
nv = sum(mat~=0);
%y location of median value
ind = size(mat,1)-nv+(nv+rem(nv,2))/2;
%get value
y=mat(sub2ind(size(mat),ind,1:size(nv,2)));
end


function [tempQ,tempM,invalidationTemplate]=loadTemplates()


tempQ=[...
    1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1
    1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0
    1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  0  0
    0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1
    0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1
    0  1  1  1  1  0  1  1  1  1  0  1  1  1  1  0  1  1  1  1  0  1  1  1  1
    0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1
    1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0
    1  1  1  1  0  1  1  1  1  0  1  1  1  1  0  1  1  1  1  0  1  1  1  1  0
    1  1  0  0  0  1  1  1  0  0  1  1  1  1  0  1  1  1  1  1  1  1  1  1  1
    1  0  0  0  0  1  1  0  0  0  1  1  1  0  0  1  1  1  1  0  1  1  1  1  1
    1  1  1  1  1  0  1  1  1  1  0  0  1  1  1  0  0  0  1  1  0  0  0  0  1
    1  1  1  1  1  1  1  1  1  1  0  1  1  1  1  0  0  1  1  1  0  0  0  1  1
    1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  1  1  1  0  0  1  1  0  0  0
    1  1  1  1  1  1  1  1  1  0  1  1  1  0  0  1  1  0  0  0  1  0  0  0  0
    0  0  0  0  1  0  0  0  1  1  0  0  1  1  1  0  1  1  1  1  1  1  1  1  1
    0  0  0  1  1  0  0  1  1  1  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1
    1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  1  0  0  0  0  0  0  0  0  0
    0  0  0  0  0  0  0  0  0  1  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1
    1  1  0  0  0  1  1  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  1  0
    0  1  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  1  1  0  0  0  1  1
    0  0  0  0  0  1  1  1  1  0  1  1  1  1  0  1  1  1  1  0  1  1  1  1  0
    1  1  1  1  0  1  1  1  1  0  1  1  1  1  0  1  1  1  1  0  0  0  0  0  0
    0  0  0  0  0  0  1  1  1  1  0  1  1  1  1  0  1  1  1  1  0  1  1  1  1
    0  1  1  1  1  0  1  1  1  1  0  1  1  1  1  0  1  1  1  1  0  0  0  0  0
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0
    0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0
    0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0  0  0  0  0  0
    0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  1  1  1  1  1  0  0  0  0  0
    0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0
    0  0  1  1  0  0  0  1  1  0  0  0  1  1  0  0  0  1  1  0  0  0  1  1  0
    0  1  1  0  0  0  1  1  0  0  0  1  1  0  0  0  1  1  0  0  0  1  1  0  0
    ]'==1;

tempM=[
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %1
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %2
    0  0  1  0  0  0  1  1  1  0  1  1  1  1  1  0  0  0  0  0  0  0  0  0  0 %3
    0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  0  1  1  1  0  0  0  1  0  0 %4
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %5
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %6
    0  0  1  0  0  0  0  1  1  0  0  0  1  1  1  0  0  1  1  0  0  0  1  0  0 %7
    0  0  1  0  0  0  1  1  0  0  1  1  1  0  0  0  1  1  0  0  0  0  1  0  0 %8
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %9
    0  0  0  0  0  0  1  1  0  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %10
    0  0  0  0  0  0  1  0  0  0  1  1  1  0  0  0  1  1  1  0  0  0  1  0  0 %11
    0  0  1  0  0  0  1  1  1  0  0  0  1  1  1  0  0  0  1  0  0  0  0  0  0 %12
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  0  1  1  0  0  0  0  0  0 %13
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  0  0  0  0  0  0  0 %14
    0  0  1  0  0  0  1  1  1  0  1  1  1  0  0  0  1  0  0  0  0  0  0  0  0 %15
    0  0  0  0  0  0  0  0  1  0  0  0  1  1  1  0  1  1  1  0  0  0  1  0  0 %16
    0  0  0  0  0  0  0  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %17
    0  0  1  0  0  0  1  1  1  0  1  1  1  0  0  0  0  0  0  0  0  0  0  0  0 %18
    0  0  0  0  0  0  0  0  0  0  0  0  1  1  1  0  1  1  1  0  0  0  1  0  0 %19
    0  0  0  0  0  0  1  0  0  0  1  1  1  0  0  0  1  1  0  0  0  0  1  0  0 %20
    0  0  1  0  0  0  0  1  1  0  0  0  1  1  1  0  0  0  1  0  0  0  0  0  0 %21
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %22
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %23
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %24
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %25
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %26
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %27
    0  0  0  0  0  0  1  1  1  0  1  1  1  1  1  0  0  0  0  0  0  0  0  0  0 %28
    0  0  0  0  0  0  0  0  0  0  1  1  1  1  1  0  1  1  1  0  0  0  0  0  0 %29
    0  0  0  0  0  0  1  1  1  0  0  1  1  1  0  0  1  1  1  0  0  0  0  0  0 %30
    0  0  1  0  0  0  0  1  1  0  0  0  1  1  0  0  0  1  1  0  0  0  1  0  0 %31
    0  0  1  0  0  0  1  1  0  0  0  1  1  0  0  0  1  1  0  0  0  0  1  0  0 %32
    ]'==1;

% gker = fspecial('gaussian',[5 5 ])>1e-4;

tempQ=[tempQ ~tempQ];
tempM=[tempM tempM*0];

invalidationTemplate = (tempQ(13,:)==false);
tempM(:,invalidationTemplate)=false;


if(0)
    figure(1);clf
    n = ceil(sqrt(size(tempQ,2)));
    arrayfun(@(i) {subaxis(n,n,i,'spacing',0.03,'margin',0.03),imagesc(reshape(double(tempQ(:,i)),[5 5])),title(i),set(gca,{'XTick','yTick', 'DataAspectRatio','clim'},{[],[],[1 1 1],[0 1]})},1:size(tempQ,2),'uni',0);
    colormap gray
    figure(2);clf
    arrayfun(@(i) {subaxis(n,n,i,'spacing',0.03,'margin',0.03),imagesc(reshape(tempM(:,i),[5 5])),title(i),set(gca,{'XTick','yTick', 'DataAspectRatio','clim'},{[],[],[1 1 1],[0 1]})},1:size(tempQ,2),'uni',0);
    colormap gray
end


end
