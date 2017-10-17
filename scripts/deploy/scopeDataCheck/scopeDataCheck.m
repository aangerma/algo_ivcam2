function scopeDataCheck
defVal='';
if(exist('.scopeDaCheck.ini','file'))
    defVal = fileread('.scopeDaCheck.ini');
end
[fn,d]=uigetfile({'*.h5','*.bin'},'Select scope data for validation',defVal);
if(isempty(fn))
    return;
end
fullfn = fullfile(d,fn);

fid=fopen('.scopeDaCheck.ini','w');
fprintf(fid,'%s',fullfn);
fclose(fid);
e = Pipe.convertScopeData2pipeInput(fullfn);
if(isempty(e))
    e='all ok';
end
msgbox(e);
end