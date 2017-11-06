function dispStruct(strct)
    fields = fieldnames(strct);
    for i=1:length(fields)
        fprintf('%s:\n',fields{i})
        if isstruct(strct.(fields{i}))
            dispStruct(strct.(fields{i}))
        else
            disp(strct.(fields{i}))
        end
        
    end
end