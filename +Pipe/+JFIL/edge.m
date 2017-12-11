function [jStream] = edge(jStreamIn,  regs, luts ,instance, lgr,traceOutDir)%#ok
jStream = jStreamIn;
lgr.print2file('\t\t------- edge -------\n');

% Median filter that is edge-aware
debug = 0;

%modes:
%  | config (2b) | bypass(1b) |  -> total 3b
% XX1 - bypass
% 000 - apply on all pixels
% 010 - do not apply on valid IR
% 100 - do not apply on valid depth
% 110 - do not apply on both valid IR and valid depth


if(debug)
    figure;subplot(131);imagesc(jStream.depth);title('d');subplot(132);imagesc(jStream.ir);title('ir');subplot(133);imagesc(jStream.conf);title('c');linkaxes;subplotTitle('input to edge');
end


bypassMode = fliplr(dec2bin(regs.JFIL.([instance,'bypassMode']),3)=='1'); %bypassMode(1)<--LSB
if( bypassMode(1) == 0  )
    
    % predefined
    Wsize = [3 3];
    S = size(jStream.depth);
    n=S(1)*S(2);
    Wind = Utils.indx2col(S,Wsize); % indexs of 3X3 patches: margins pad by NN replication
    % W =[a(1) a(2) a(3);
    %     b(4)  0   a(4);
    %     b(3) b(2) b(1)];
    aInd = [1 4 7 8];
    bInd = [9 6 3 2];
    
    
    
    
    
    %patch with pair diff above RegsDetectTh && pair diff below RegsMaxTh
    %means that we have 2 different planes in the patch and the edge is in
    %the index of the pair with diff below RegsMaxTh
    RegsMaxTh = regs.JFIL.(sprintf('%smaxTh',instance));
    RegsDetectTh = regs.JFIL.(sprintf('%sdetectTh',instance));
     assert(RegsMaxTh < RegsDetectTh);

    
    
    % validness maps
    validMask = (jStream.conf>0);
    validBox = validMask(Wind);
    aValidBox = validBox(aInd,:);
    bValidBox = validBox(bInd,:);
    
    
    
    % group in 3*3
    dBox = jStream.depth(Wind);
    iBox = jStream.ir(Wind);
    cBox = jStream.conf(Wind);
    
    % get a & b of each window
    aDBox = dBox(aInd,:);
    bDBox = dBox(bInd,:);
    aIBox = iBox(aInd,:);
    bIBox = iBox(bInd,:);
    aCBox = cBox(aInd,:);
    bCBox = cBox(bInd,:);
    
    
    % |a_i-b_i| for each window
    diffMat = uint16(abs(double(aDBox)-double(bDBox)));
    
    
    
    
    % When some of the 8 pixels are invalid, the corespondend difference is set
    % so it will not show up
    diffMatForMin = diffMat;
    diffMatForMax = diffMat;
    diffMatForMin(aValidBox==0 | bValidBox==0) = 2^16-1;
    diffMatForMax(aValidBox==0 | bValidBox==0) = 0;
    
    
    
    % vars like in the doc
    [minDiff,edgeDirection] = min(diffMatForMin,[],1);
    maxDiff = max(diffMatForMax,[],1);
    isAboveRegsDetectTh = (maxDiff >= RegsDetectTh);
    
    
    
    
    %new vars for inputs
    newD = jStream.depth;
    newI = jStream.ir;
    newC = jStream.conf;
    
    %find median indexs - if all nieghbors are invalids, the center pixel
    %remains invalid
    dBoxTmp = double(dBox);
    dBoxTmp(validBox == 0) = 0;
    [dMedVal,dMedYind] = myFastMedian(dBoxTmp);
    dMedInd = sub2ind(size(dBoxTmp),dMedYind,1:n);
%      medIndPerCol = find_ndim(dBoxTmp==repmat(dMedVal,9,1),1); % if 0 then all the window is invalid
%     dMedInd = medIndPerCol-9+cumsum(9*ones(1,n));
%     dMedInd(medIndPerCol==0) = nan;
    dMedInd(dMedVal==0)=nan;
    % do 3X3 median on depth image- keep invalid as invalid
    newD(~isnan(dMedInd)) = dBox(dMedInd(~isnan(dMedInd)));
    newC(~isnan(dMedInd)) = cBox(dMedInd(~isnan(dMedInd)));
    
    
    %and median for IR- do for all pixel- because in IR there are no invalids
    iBoxTmp = double(iBox);
    iBoxTmp(validBox == 0) = 0;
    iMedVal = myFastMedian(iBoxTmp);
    newI(~isnan(iMedVal)) = iMedVal(~isnan(iMedVal));
    
    
    %override with preserved edges - edges will not recongnize invalid as edge
    %due to given thresholds...
    edgeDirectionInd = sub2ind(size(aDBox),edgeDirection(:),vec(1:size(aDBox,2)));
    edgeDirectionInd = edgeDirectionInd(minDiff<RegsMaxTh & isAboveRegsDetectTh);
    
    if(debug)
        figure;subplot(131);imagesc(newD);title('d');subplot(132);imagesc(newI);title('ir');subplot(133);imagesc(newC);title('c');linkaxes;subplotTitle('before edge after median');
        figure;imagesc(reshape(minDiff<RegsMaxTh & isAboveRegsDetectTh,S));title('detected edges');
    end
    
    
    newD(minDiff<RegsMaxTh & isAboveRegsDetectTh) = bitshift(uint32(aDBox(edgeDirectionInd))+uint32(bDBox(edgeDirectionInd)),-1);
    newI(minDiff<RegsMaxTh & isAboveRegsDetectTh) = bitshift(uint32(aIBox(edgeDirectionInd))+uint32(bIBox(edgeDirectionInd)),-1);
    newC(minDiff<RegsMaxTh & isAboveRegsDetectTh) = bitshift(uint32(aCBox(edgeDirectionInd))+uint32(bCBox(edgeDirectionInd)),-1);
    
    

    if( bypassMode(2)==0 )
		%on all image
        jStream.ir = newI;
    else
		%on invalids only
        jStream.ir(~validMask) = newI(~validMask);

    end
    if( bypassMode(3)==0)
		%on all image
        jStream.depth = newD;
        jStream.conf = newC;
    else
		%on invalids only
        jStream.depth(~validMask) = newD(~validMask);
        jStream.conf(~validMask) = newC(~validMask);

    end
end

% debug mode
if (isfield(jStream,'debug'))
    jStream.debug{end+1}={instance,jStream.depth,jStream.ir,jStream.conf};
end


Pipe.JFIL.checkStreamValidity(jStream,instance,false);

if(~isempty(traceOutDir) )
    Utils.buildTracer([dec2hexFast(jStream.ir,3) dec2hexFast(jStream.conf,1) dec2hexFast(jStream.depth,4)],['JFIL_' instance],traceOutDir);
end

if(debug)
    %%
    figure(453323);clf 
    name = {'depth','ir','conf'};
    a = zeros(9,1);
    for i=1:3
        a(1+(i-1)*3) = subplot(3,3,1+(i-1)*3);
        before = jStreamIn.(name{i});
        if(strcmp(name{i},'depth'))
            before(before<6000 | before>7000) = nan;
        end
        imagesc(before);
        title([name{i} ' before edge']);
        
        after = jStream.(name{i});
        if(strcmp(name{i},'depth'))
            after(after<6000 | after>7000) = nan;
        end
        a(2+(i-1)*3) = subplot(3,3,2+(i-1)*3);
        imagesc(after);
        title([name{i} ' after edge']);
        
        dif = abs(double(before)-double(after));
        % dif(isnan(before) | isnan(after)) = nan;
        a(3+(i-1)*3) = subplot(3,3,3+(i-1)*3);
        imagesc(dif);
        title(['max dif is ' num2str(max(dif(:)))]);
    end
    linkaxes(a);
end

lgr.print2file('\t\t----- end edge -----\n');

end





% 
% 
% function varargout = find_ndim( BW, dim, firstOrLast )
% %FIND_NDIM   Finds first/last nonzero element indices along a dimension.
% %   I = FIND_NDIM(BW,DIM) returns the subscripts of the first nonzero
% %   elements of BW along the dimension DIM. Output I will contain zeros in
% %   element locations where no nonzero elements were found
% %
% %   I = FIND_NDIM(BW,DIM,'first) is the same as I = FIND_NDIM(BW,DIM).
% %
% %   I = FIND_NDIM(BW,DIM,'last') returns the subscripts of the last nonzero
% %   elements of BW along the dimension DIM.
% %
% %   [I,MASK] = FIND_NDIM(BW,DIM,...) also returns a MASK the same size as
% %   BW with only the first/last pixels in dimension DIM on.
% %
% %     Example 1:
% %         If   X = [0 1 0
% %                   1 1 0]
% %         then find_ndim(X,1) returns [2 1 0], find_ndim(X,1,'last')
% %         returns [2 2 0], and find_ndim(X,2) returns [2 1]';
% %
% %     Example 2:
% %         I = imread('rice.png');
% %         greyIm = imadjust(I - imopen(I,strel('disk',15)));
% %         BW = imclearborder(bwareaopen(im2bw(greyIm, graythresh(greyIm)), 50));
% %         topMostOnInds = find_ndim(BW, 1, 'first');
% %         rightMostOnInds = find_ndim(BW, 2, 'last');
% %         figure, imshow(BW), hold on
% %         plot(1:size(BW,2), topMostOnInds, 'r.')
% %         plot(rightMostOnInds, 1:size(BW,1), '.b')
% %
% %   See also MAX, FIND.
% 
% % Written by Sven Holcombe
% 
% assert(nargin>=2,'Insufficient arguments')
% 
% % Handle non-logical input
% if ~isa(BW,'logical')
%     BW = BW~=0;
% end
% 
% % Determine whether we're finding first/last entry
% if nargin < 3 || strcmpi(firstOrLast,'first')
%     firstOrLast = 'first';
% elseif nargin == 3 && strcmpi(firstOrLast,'last')
%     BW = flip(BW,dim); % If they asked to find last entry, flip in that direction
% else
%     error('find_ndim:searchOption','Invalid search option. Must be ''first'' or ''last''')
% end
% 
% % Hijack the max function. Input is logical so max idx will be first pixel
% [~, foundPx] = max(BW,[],dim);
% foundPx(~any(BW,dim)) = 0; % Account for all-zero entries by setting output to 0
% 
% % If they asked to find last entry, account for previously flipping BW
% if strcmpi(firstOrLast,'last')
%     foundPx(foundPx~=0) = size(BW,dim)+1 - foundPx(foundPx~=0);
% end
% varargout{1} = foundPx;
% 
% % If they asked for a full MASK of found pixels:
% if nargout==2
%     indsSz = ones(1,ndims(BW));
%     indsSz(dim) = size(BW,dim);
%     varargout{2} = bsxfun(@eq, foundPx, reshape(1:size(BW,dim), indsSz));
% end
% end


function [y,ind] = myFastMedian(matIn)

[mat,indices] = sort(matIn,1);
% number of valid element in each column
nv = sum(mat~=0);
%y location of median value
medValInd = size(mat,1)-nv+(nv+rem(nv,2))/2;
%get value
medMatInd = sub2ind(size(mat),medValInd,1:size(nv,2));
y=mat(medMatInd);
ind = indices(medMatInd);
end

%
% function y = mynanmedianlow(x,dim) %% The purpose of this median is to avoid MATLAB median when we have an even number of valid numbers.
%
% % FORMAT: Y = NANMEDIAN(X,DIM)
% %
% %    Median ignoring NaNs
% %
% %    This function enhances the functionality of NANMEDIAN as distributed
% %    in the MATLAB Statistics Toolbox and is meant as a replacement (hence
% %    the identical name).
% %
% %    NANMEDIAN(X,DIM) calculates the mean along any dimension of the N-D
% %    array X ignoring NaNs.  If DIM is omitted NANMEDIAN averages along the
% %    first non-singleton dimension of X.
% %
% %    Similar replacements exist for NANMEAN, NANSTD, NANMIN, NANMAX, and
% %    NANSUM which are all part of the NaN-suite.
% %
% %    See also MEDIAN
%
% % -------------------------------------------------------------------------
% %    author:      Jan Gläscher
% %    affiliation: Neuroimage Nord, University of Hamburg, Germany
% %    email:       glaescher@uke.uni-hamburg.de
% %
% %    $Revision: 1.2 $ $Date: 2007/07/30 17:19:19 $
%
% if isempty(x)
%     y = [];
%     return
% end
%
% if nargin < 2
%     dim = min(find(size(x)~=1));
%     if isempty(dim)
%         dim = 1;
%     end
% end
%
% siz  = size(x);
% n    = size(x,dim);
%
% % Permute and reshape so that DIM becomes the row dimension of a 2-D array
% perm = [dim:max(length(size(x)),dim) 1:dim-1];
% x = reshape(permute(x,perm),n,prod(siz)/n);
%
%
% % force NaNs to bottom of each column
% x = sort(x,1);
%
% % identify and replace NaNs
% nans = isnan(x);
% x(isnan(x)) = 0;
%
% % new dimension of x
% [n m] = size(x);
%
% % number of non-NaN element in each column
% s = size(x,1) - sum(nans);
% y = zeros(size(s));
%
% % now calculate median for every element in y
% % (does anybody know a more eefficient way than with a 'for'-loop?)
% for i = 1:length(s)
%     if rem(s(i),2) & s(i) > 0
%         y(i) = x((s(i)+1)/2,i);
%     elseif rem(s(i),2)==0 & s(i) > 0
%         y(i) = x(s(i)/2,i);
%     end
% end
%
% % Protect against a column of NaNs
% i = find(y==0);
% y(i) = i + nan;
%
% % permute and reshape back
% siz(dim) = 1;
% y = ipermute(reshape(y,siz(perm)),perm);
%
% % $Id: nanmedian.m,v 1.2 2007/07/30 17:19:19 glaescher Exp glaescher $
% end
