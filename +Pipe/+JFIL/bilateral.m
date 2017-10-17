function [ jStream ] = bilateral( jStream, regs, luts, instance, lgr,traceOutDir )

lgr.print2file('\t\t------- bilateral -------\n');

if(~regs.JFIL.(sprintf('%sbypass',instance)))
    zMaxSubMMExp = double(regs.GNRL.zMaxSubMMExp);
    
    dImg = jStream.depth;
    confImg = jStream.conf;
    irImg = jStream.ir;
    
    sz = size(dImg);
    
    biltDepth = ~strcmp(instance, 'biltIR');
    
    %% boxes
    indx = Utils.indx2col(size(dImg),[5 5]);
    indx = reshape(indx,[25 size(dImg)]);
    depthBox = dImg(indx);
    irBox = irImg(indx);
    
    %% central pixel
    if (biltDepth) % depth image
        cpBox = repmat(reshape(dImg, [1 sz(1) sz(2)]), [25 1 1]); % central pixel
        rdBox = uint16(abs(int32(cpBox)-int32(depthBox))); % radiometric diff
        rdBox = min(rdBox, 2^12-1); % reduce range to 12bit by clipping
    else % ir image
        cpBox = repmat(reshape(irImg, [1 sz(1) sz(2)]), [25 1 1]); % central pixel
        rdBox = uint16(abs(int32(cpBox)-int32(irBox))); % radiometric diff
    end
    
    %% load gaussians for spatial weights
    gaussLUT = reshape(regs.JFIL.biltGauss, 6, 32);
    gauss = zeros(5,5,32, 'uint8');
    
    for i=1:32
        g = zeros(3,3,'uint8');
        ind = sub2ind([3 3], [3 2 1 2 3 3], [3 2 1 1 2 1]);
        g(ind) = gaussLUT(:,i);
        ind = sub2ind([3 3], [1 2 1], [2 3 3]);
        g(ind) = gaussLUT([4 5 6],i);
        
        gauss(1:3,1:3,i) = g;
        gauss(3:5,1:3,i) = flipud(g);
        gauss(1:3,3:5,i) = fliplr(g);
        gauss(3:5,3:5,i) = rot90(rot90(g));
    end
    
    Gauss = reshape(gauss, [25 32]);
    
    %% spatial weights
    sConfAdapt = (bitand(regs.JFIL.biltAdaptS, 1) ~= 0);
    if (sConfAdapt && biltDepth)
        sConfAdaptImg = regs.JFIL.biltConfAdaptS(confImg+1);
    else
        sConfAdaptImg = 16;
    end
    
    if (biltDepth) % depth image
        sDepthAdapt = (bitand(regs.JFIL.biltAdaptS, 2) ~= 0);
        if (sDepthAdapt)
            sDepthAdaptImg = regs.JFIL.biltDepthAdaptS(min(bitshift(dImg, -zMaxSubMMExp-3),255)+1);
        else
            sDepthAdaptImg = 16;
        end
        
        sSharpness = regs.JFIL.biltSharpnessS; % rdSharpness : 0..63, default 16
    else % IR image
        sValueAdapt = (bitand(regs.JFIL.biltIRAdaptS, 1) ~= 0);
        if (sValueAdapt)
            sDepthAdaptImg = regs.JFIL.biltIRValueAdaptS(bitshift(irImg, -6)+1);
        else
            sDepthAdaptImg = 16;
        end
        
        sSharpness = regs.JFIL.biltIRSharpnessS; % rdSharpness : 0..63, default 16
    end
    
    %% saBox: spatial adaptive box 5bit*5bit*5bit=32bit -> 5bit
    saImg = uint16(bitshift(...
        uint32(sDepthAdaptImg) .*... % 5bit
        uint32(sConfAdaptImg) .* uint32(sSharpness),... % 5bit * 5bit
        -4-4));
    
    if (numel(saImg) == 1)
        Ws = repmat(Gauss(:,min(saImg,31)+1),[1,size(depthBox,2),size(depthBox,3)]);
    else
        Ws = reshape(Gauss(:,min(saImg,31)+1), size(depthBox));
    end
    
    %% radiometric weights
    
    rConfAdapt = (bitand(regs.JFIL.biltAdaptR, 1) ~= 0);
    if (rConfAdapt && biltDepth)
        rConfAdaptBox = regs.JFIL.biltConfAdaptR(confImg(indx)+1);
    else
        rConfAdaptBox = 16;
    end
    
    if (biltDepth) % depth image
        rDepthAdapt = (bitand(regs.JFIL.biltAdaptR, 2) ~= 0);
        if (rDepthAdapt == 1)
            rDepthAdaptBox = regs.JFIL.biltDepthAdaptR(bitshift(cpBox, -8)+1);
        else
            rDepthAdaptBox = regs.JFIL.biltDepthAdaptR(1);
        end
        
        regSharpnessR=sprintf('%sSharpnessR',instance);
        rSharpness = regs.JFIL.(regSharpnessR); % rdSharpness : 0..63, default 16
        
    else % IR image
        rVlaueAdapt = (bitand(regs.JFIL.biltIRAdaptR, 1) ~= 0);
        if (rVlaueAdapt == 1)
            rDepthAdaptBox = regs.JFIL.biltIRValueAdaptR(bitshift(cpBox, -6)+1);
        else
            rDepthAdaptBox = regs.JFIL.biltIRValueAdaptR(64);
        end
        
        rSharpness = regs.JFIL.biltIRSharpnessR; % rdSharpness : 0..63, default 16
    end
    
    if (biltDepth) % depth
        rdaShift = -3-5-4-zMaxSubMMExp;
    else % IR
        rdaShift = -6-5-4;
    end
    
    % rdaBox: radiometric adaptive box 12bit*8bit*6bit*6bit=32bit -> 6bit
    rdaBox = uint16(bitshift(...
        uint32(rdBox) .* ... % 12bit
        uint32(rDepthAdaptBox) .*... % 8bit
        uint32(rConfAdaptBox) .* uint32(rSharpness),... % 6bit * 6bit
        rdaShift));
    
    Wr = regs.JFIL.biltSigmoid(min(rdaBox,63)+1); % 8 bit
    
    %% conf weights
    confMask = uint8(jStream.conf >= regs.JFIL.biltConfThr);
    
    if (regs.JFIL.biltConfMaskD == 0)
        confW = confMask;
    else
        confWeight = uint8(regs.JFIL.biltConfWeightD(confImg+1));
        confW = confWeight .* confMask;
    end
    
    if (biltDepth) % depth
        Wc = confW(indx);
        vBox = depthBox;
    else
        Wc = 1;
        vBox = irBox;
    end
    
    %% weights
    % 8bit * 8bit * 5bit => 21bit
    W = uint64(Wr) .* uint64(Ws) .* uint64(Wc);
    
    dMul = uint64(vBox) .* W;
    dNum = squeeze(sum(dMul, 1, 'native'));
    wSum = squeeze(sum(W, 1, 'native'));
    
    %denom = single(1)./single(double(wSum));
% 	denomU64 = typecast(reshape(1./double(wSum),1,[]), 'uint64');
%   denomRoundMask = bitcmp(uint64(2^26-1));
% 	denomU64round = bitand(denomU64, denomRoundMask);
% 	denom = single(reshape(typecast(denomU64round, 'double'), size(wSum)));

    if(regs.MTLB.fastApprox(3))
        denom = 1./single(wSum);
    else
        denom = Utils.fp32('inv',single(wSum));
    end
    
    denom(wSum == 0) = 0;

    dNumH = int32(bitshift(dNum, -30));
    dNumL = int32(bitand(dNum, uint64(2^30-1)));
    blRes = floor(single(dNumH).*denom.*single(2^30-1)+single(dNumL).*denom+.5);    
    %% blRes = round(single(double(dNum)).*denom);
    
    
    
    %% update output
    
    if (biltDepth) % depth
        % bilateral does not affect pixels with conf == 0
        indZeros = and(dImg == 0, confImg == 0);
        blRes(indZeros) = dImg(indZeros);
        
        nonConf = ~(jStream.conf >= regs.JFIL.biltConfThr);
        blRes(nonConf) = dImg(nonConf);
        
        jStream.depth = uint16(min(blRes, 2^16-1));
    else
        jStream.ir = uint16(min(blRes, 2^12-1));
    end
end

if (isfield(jStream,'debug'))
    jStream.debug{end+1}={instance,jStream.depth,jStream.ir,jStream.conf};
end

invPixels = ((jStream.depth~=0) ~= (jStream.conf~=0));
if (any(invPixels(:)))
    centralPxWs = squeeze(Ws(13,:,:));
    if (nnz(and(invPixels, centralPxWs ~= 0)) == 0)
       error('All invalid depth/confidence combinations are due to bad (zero) spatial weights of central pixels');
    end
end

Pipe.JFIL.checkStreamValidity(jStream,instance,false);
if(~isempty(traceOutDir) )

    Utils.buildTracer([dec2hexFast(jStream.ir,3) dec2hexFast(jStream.conf,1) dec2hexFast(jStream.depth,4)],['JFIL_' instance],traceOutDir);
end

lgr.print2file('\t\t----- end bilateral -----\n');

end