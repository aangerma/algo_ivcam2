function [t,v]=importScopeDataWpolarity(fn,indx)
[~,~,ext]=fileparts(fn);
switch(ext(2:end))
    case 'bin'
        [t,v]=io.POC.importAgilentBin(fn,abs(indx));
    case 'h5'
        [t0,dt,v]=io.POC.readScopeHDF5data(fn,abs(indx));
        t = t0 + (0:length(v)-1)*dt;
    otherwise
        error('unknonwn filetype');
end
if(indx<0)
    v=-v;
end
end