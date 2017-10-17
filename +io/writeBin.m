function [] = writeBin(fname,data,varargin)
    

    p = inputParser;
    
    addRequired(p,'fname',@ischar);
    addRequired(p,'data');
    
    fname = strrep(fname,'"','');
    [folder,file,ext] = fileparts(fname);
    
    defaultType = ext(2:end);
    
    expectedTypes = {'binz','bini','binr','binv','binc','bint','bin8','bin12','bin16','bin32','stl'};
    
    addParameter(p,'type',defaultType,...
        @(x) any(validatestring(x,expectedTypes)));
    
    parse(p,fname,data,varargin{:});
    
    if isempty(p.Results.type)
        error('Without fname extension, ''type'' must be specified!');
    end
    
    fullname = fullfile(folder,[file,ext]);
    f = fopen(fullname,'wb');
    switch p.Results.type
        case 'binz'
            fwrite(f,data,'uint16');
        case 'bini'
            fwrite(f,data,'uint16');
        case 'binr'
            
            data(isnan(data))=0;
            data = max(min(data,2^13-1),0);
            data16 = uint16(data*8);%assumes max depth of 2^13. mult by 2^3 for sub millimeter reslution.
            fwrite(f,vec(data16'),'uint16');
        case 'binv'
            
            vertices =[vec(flipud(data(:,:,1))') vec(flipud(data(:,:,2))') vec(flipud(data(:,:,3))')]';
            fwrite(f,vertices(:),'float');
        case 'binc'
            fwrite(f,vec(data'),'uint16');
        case 'bint'
            rgb =[vec(data(:,:,1)') vec(data(:,:,2)') vec(data(:,:,3)')]';
            fwrite(f,rgb(:),'uint8');
        case 'stl'
             stlwriteMatrix(f,data.xImg,data.yImg,data.zImg,'color',double(data.iImg),'verbose',false,'facetsDirUp',false);            
        case {'bin8','bin12','bin16','bin32'}
            ubitn = strrep(p.Results.type,'bin','ubit');
            fwrite(f,vec(data'),ubitn);
    end
    fclose(f);
end


