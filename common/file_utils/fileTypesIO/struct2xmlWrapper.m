function ok = struct2xmlWrapper(s,fn,sname)
    if(~exist('sname','var'))
        sname = 'struct';
    end
    for i=1:length(s)
        s4save = addTextField(s(i));
        s4saveHeader(i).(sname)=s4save; %#ok
    end
    %check write premission
    fid = fopen(fn,'w');
    if(fid==-1)
        ok=false;
        return;
    end
    fclose(fid);
    struct2xml(s4saveHeader,fn);
    ok = true;
end

function sout=addTextField(sin)
    f = fieldnames(sin);
    for i=1:length(f)
        if(isstruct(sin.(f{i})))
            sout.(f{i})=addTextField(sin.(f{i}));
        elseif(isnumeric(sin.(f{i})))
            sout.(f{i}).Text=mat2str(sin.(f{i}),64);
        elseif(islogical(sin.(f{i})))
            sout.(f{i}).Text=mat2str(sin.(f{i}));
        elseif(ischar(sin.(f{i})))
            sout.(f{i}).Text=sin.(f{i});
        elseif(isa(sin.(f{i}),'function_handle'))
            sout.(f{i}).Text=func2str(sin.(f{i}));
        else
            %???
        end
        
    end
end