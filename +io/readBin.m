function [img] = readBin(fname,varargin)
imgSizes = {[320 240],[640 480],[1280 960],[1280 720],[64 64],[540 840]};
p = inputParser;

addRequired(p,'fname',@ischar);
fname = strrep(fname,'"','');
[folder,file,ext] = fileparts(fname);

defaultSize = [];
defaultType = ext(2:end);

expectedTypes = {'raw','binz'  ,'bini'  ,'binr'  ,'binv' ,'binc' ,'bint' ,'bin8' ,'bin12' ,'bin16' ,'bin32'};
readTypes     = {'uint8','uint16','uint16','uint16','float','uint16','uint8','ubit8','ubit12','ubit16','float'};
castType      = {'uint8','uint16','uint16','uint16','float','uint16','uint8','uint8','uint16','uint16','single'};

addOptional(p,'size',defaultSize,@isnumeric);
addParameter(p,'type',defaultType,...
    @(x) any(validatestring(x,expectedTypes)));

parse(p,fname,varargin{:});
p=p.Results;

if isempty(p.type)
    error('Without fname extension, ''type'' must be specified!');
end

fullname = fullfile(folder,[file,ext]);
f = fopen(fullname,'rb');
ind = find(strcmpi(p.type,expectedTypes),1);
if(isempty(ind))
    error('unknown file type');
end
buffer = fread(f,Inf,readTypes{ind});
fclose(f);

buffer = cast(buffer,castType{ind});
if(~isempty(p.size))
    sz=p.size;
else
    n = numel(buffer);
    nch=getNch(p.type);
    
    
    r=cellfun(@(x) n/(nch*prod(x)),imgSizes);
    r = abs(r-1);
    if(any(r==0))
        sz = imgSizes{r==0};
    elseif(any(r==eps))
        sz = imgSizes{r==eps};
    else
        sz = [n 1];
    end
end
switch p.type
    case {'raw','binz','bini','binc','bin8','bin12','bin16','bin32'}
        img = reshape(buffer,sz)';
        
    case 'binr'
        data = double(buffer)/8;%assumes max depth of 2^13. mult by 2^3 for sub millimeter reslution.
        img = reshape(data,sz)';
    case {'bint','binv'}
        img(:,:,1) = reshape(buffer(1:3:end),sz)';
        img(:,:,2)  = reshape(buffer(2:3:end),sz)';
        img(:,:,3)  = reshape(buffer(3:3:end),sz)';
        
end

end

function n=getNch(s)
switch s
    case {'raw','binz','bini','binc','bin8','bin12','bin16','bin32','binr'}
        n=1;
    case {'bint','binv'}
        n=3;
    otherwise
        error('unkonwn type %s',s);
end
end
