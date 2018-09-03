function compile_mex(debug)
if(~exist('debug','var'))
    debug=false;
end
if(debug)
    fprintf('***compiling in debug mode****\n');
end
thisinc = fileparts(which(mfilename));
if(isempty(which('Pipe.autopipe')))
    error('Could not find Pipe entry point');
end
baseDir = fileparts( fileparts(which('Pipe.autopipe')));
f= dirRecursive(baseDir,'*.cpp');
mxlen = max(cellfun(@(x) length(filename(x)),f))+3;
for i=1:length(f)
    if(isempty(strfind(fileread(f{i}),'mexFunction(')))
        %not a mexfunction
        continue;
    end
    [bd,fn]=fileparts(f{i});
    ndots = repmat('.',1,mxlen-length(fn));
    fprintf('Compiling %s%s',fn,ndots);
    try
        if(exist([bd filesep 'compile_' fn '.m'],'file'))
            run([bd filesep 'compile_' fn '.m']);
        else
            if(debug)
                dbgf='-g';
            else
                dbgf='';
            end
            if(isunix)
                mex(f{i},dbgf,'-outdir',bd,['-I',thisinc],['-I',bd],'-silent','-largeArrayDims');
            else
                mex(f{i},dbgf,'-outdir',bd,['-I',thisinc],['-I',bd],'-silent','-largeArrayDims');
            end
        end
        fprintf('SUCCESS\n');
        
    catch e
        sep = repmat('-',1,length(e.message));
        fprintf('FAILED\n%s\n%s%s\n',sep,e.message,sep);
    end
end
end

function n=filename(f)
[~,n]=fileparts(f);

end