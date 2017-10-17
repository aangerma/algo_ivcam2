
baseDir = 'M:\SOURCE\IVCAM\Algo\LIDAR\+Pipe';
d=dirFolders(baseDir,'+*');
blockRegs=cell(length(d),1);
for i=1:length(d)
    f = dirFiles(d{i},'*.m');
    for j=1:length(f)
        txt = fileread(f{j});
        res = regexp(txt,'regs\.(?<n>[\dA-z\._]+)','names');
        blockRegs{i} = [blockRegs{i} strrep(strrep(strcat('Regs',{res.n}),'.',''),']','')];
    end
    blockRegs{i}=unique(blockRegs{i});
end
%%
for i=1:length(d)
    fprintf('%s,',d{i}(find(d{i}=='+',1,'last')+1:find(d{i}=='+',1,'last')+4))
    fprintf('%s,',blockRegs{i}{:})
    fprintf('\n');
end