function [ jStream ] = sort( jStreamIn, regs, luts, instance, lgr,traceOutDir )

lgr.print2file('\t\t------- sort -------\n');

jStream = jStreamIn;
%modes:
%  | config (2b) | bypass(1b) |  -> total 3b
% XX1 - bypass
% 000 - apply on all pixels
% 010 - do not apply on valid IR
% 100 - do not apply on valid depth
% 110 - do not apply on both valid IR and valid depth

%% Depth sort
bypassMode = fliplr(dec2bin(regs.JFIL.([instance,'bypassMode']),3)=='1'); %bypassMode(1)<--LSB

if( bypassMode(1) == 0  )
    
    wds=regs.JFIL.([instance,'dWeights']);
    wdc=regs.JFIL.([instance,'dWeightsC']);
    wis=regs.JFIL.([instance,'iWeights']);
    wic=regs.JFIL.([instance,'iWeightsC']);
    indx = Utils.indx2col(size(jStream.depth),[3 3]);
    patchD = jStream.depth(indx);
    patchC = jStream.conf(indx);
    patchI = jStream.ir(indx);
    
    invalids = (jStream.conf(:)==0);
    invalidsi = (jStream.ir(:)==0);
    valids = ~invalids;
    validsi = ~invalidsi;
    dMask = invalids | (valids&( bypassMode(3) ==0 )); %if bypassMode(3) ==0 do on all pixels
    iMask = invalidsi | (validsi&( bypassMode(2) ==0 )); %same
    
    jStream.depth(dMask) = applySortOnPatchImg(patchD(:,dMask),wds,wdc);
    jStream.ir(iMask)    = applySortOnPatchImg(patchI(:,iMask),wis,wic);
    
    
    %in areas where there is a hole larger than 3x3, keep conf at zero (invalid pixel)
    cMask = invalids;
    if(regs.JFIL.([instance,'doConfAveraging'])==1)
        divLut = regs.JFIL.sortInvMultiplication(1:end-1);%only 9 inputs...
        jStream.conf(cMask )=bitshift( double(uint16(sum(patchC(:,cMask ))) .* uint16( divLut ( 1+(sum(patchC(:,cMask)~=0)) ) ) +2^9 ), -10 );
    else
        jStream.conf(cMask) = regs.JFIL.([instance,'fixedConfValue']);
    end
    
end


if (isfield(jStream,'debug'))
    jStream.debug{end+1}={instance,jStream.depth,jStream.ir,jStream.conf};
end

Pipe.JFIL.checkStreamValidity(jStream,instance,false);


if(~isempty(traceOutDir) )
    Utils.buildTracer([dec2hexFast(jStream.ir,3) dec2hexFast(jStream.conf,1) dec2hexFast(jStream.depth,4)],['JFIL_' instance],traceOutDir);
end

lgr.print2file('\t\t----- end sort -----\n');

end

function outPatch=applySortOnPatchImg(patchImg,we,wc)
if(isempty(patchImg))
    outPatch = patchImg;
    return;
end
we=uint16(we);
wv = [we wc fliplr(we)]';

p=sort(patchImg);
%count number of invalid
ninv = sum(p==0);
%circshift acroding to number of invalid
[ny,nx]=ndgrid(1:size(p,1),1:size(p,2));
nyCircshift = double(Pipe.JFIL.circsort(uint16(ny),uint16(floor(ninv/2))));
p=p(sub2ind(size(p),nyCircshift,nx));
%set central pixel value to all invalid(zero) pixels
p=bsxfun(@times,uint16(p==0),p(ceil(size(p,1)/2),:)) + p;
%apply weights, divide by 256
outPatch = uint16(bitshift(uint32(double(p)'*double(wv)),-8));


end