function regs = mergeRegs(regs,autogenRegs)
    blockNames = fieldnames(autogenRegs);
    for i=1:length(blockNames)
        regNames = fieldnames(autogenRegs.(blockNames{i}));
        for j=1:length(regNames)
            regs.(blockNames{i}).(regNames{j}) = autogenRegs.(blockNames{i}).(regNames{j});
        end
    end
end