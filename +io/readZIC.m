function s = readZIC(fldr,n)
% read ZIC bin files form folder
%-if only z/i/c exists, ready it and put 0 in the others
%-resolution is obtained from filename (..._WxH_...bin)
%-input:
%  -fldr: source folder
%  -n: either number of frames to read, or cell array of which frames to
%  read. in case not all frame exists, the intersection between source and
%  request will be delivered
if(~exist('n','var'))
    n=inf;
end


i = dirFiles(fldr,'IR*.bin');
z = dirFiles(fldr,'Depth*.bin');
c = dirFiles(fldr,'Conf*.bin');
res = determineRes([i;z;c]);

zn=cellfun(@(x) fn2num(x),z);
in=cellfun(@(x) fn2num(x),i);
cn=cellfun(@(x) fn2num(x),c);


franmeNums = unique([zn(~isnan(zn));in(~isnan(in));cn(~isnan(cn))]);
if(isnumeric(n))
n=min(length(franmeNums),n);
franmeNums = franmeNums(1:n);
elseif(iscell(n))
    franmeNums=intersect(franmeNums,[n{:}]);
    n=length(franmeNums);
else
    error('Bad input');
end
zeroMat = @(type) arrayfun(@(x) zeros(res,type),1:n,'uni',0);
% 
% z=cellfun(@(x) reshape(typecast(readBin(x),'uint16'),res)',z,'uni',0);
% i=cellfun(@(x) reshape(typecast(readBin(x),'uint8' ),res)',i,'uni',0);
% c=cellfun(@(x) reshape(typecast(readBin(x),'uint8' ),res)',c,'uni',0);

s=struct('z',zeroMat('uint16'),'i',zeroMat('uint8'),'c',zeroMat('uint8'),'index',num2cell(franmeNums)');
for j=1:length(zn)
    ind=find(franmeNums==zn(j),1);
    if(isempty(ind)),        continue;    end
    s(ind).z=reshape(typecast(readBin(z{j}),'uint16'),res)';
end

for j=1:length(in)
     ind=find(franmeNums==in(j),1);
    if(isempty(ind)),        continue;    end
    s(ind).i=reshape(typecast(readBin(i{j}),'uint8'),res)';
end

for j=1:length(cn)
     ind=find(franmeNums==cn(j),1);
    if(isempty(ind)),        continue;    end
    s(ind).c=reshape(typecast(readBin(c{j}),'uint8'),res)';
end


end

function res  = determineRes(fns)
res=regexp(fns{1},'\_(?<w>\d+)x(?<h>\d+)_','names');
if(isempty(res))
    error('Could not determine resolution from filename');
end
res = str2double({res.w res.h});
end


function num=fn2num(fn)
num=regexp(fn,'\_(?<n>[\d]+)\.bin','names');
if(isempty(num))
    num=nan;
else
    num = str2double(num.n);
end
end

function d=readBin(fn)
fid = fopen(fn,'r');
d = uint8(fread(fid,'uint8'));
fclose(fid);
end
