function writeDODParamsMWD(filename, resDODParams, shortFirmwareFormat)
            
if ~exist('shortFirmwareFormat','var')
    shortFirmwareFormat = false;
end

if exist(filename, 'file') == 2
    fprintf('%s already exists. Overriding...',filename);
end

[regsOld,lutsOld] = resDODParams.initFW.get();
[regsNew,lutsNew] = resDODParams.fw.get();

newRegsNames = getDiffNames(regsNew,regsOld,lutsNew,lutsOld);
resDODParams.fw.genMWDcmd(newRegsNames, filename, shortFirmwareFormat);

[filepath,~,~] = fileparts(filename);
dodRes = fullfile(filepath,'resDODParams.mat');
save(dodRes,'resDODParams')

end

function strList = getDiffNames(regsNew,regsOld,lutsNew,lutsOld)

strListRegs = getDiffFields(regsNew,regsOld);
strListLuts = getDiffFields(lutsNew,lutsOld);
strList = strcat(strListRegs,'|',strListLuts);
end
function strList = getDiffFields(head0,head1)
strList = '';
f0 = fieldnames(head0);
for i = 1:numel(f0)
    fn0 = f0{i};
    st = head0.(fn0);
    f1 = fieldnames(st);
    for j = 1:numel(f1)
        if any(head0.(fn0).(f1{j}) ~= head1.(fn0).(f1{j}))
            strList = strcat(strList,sprintf('%s%s|',fn0,f1{j}));
        end
    end
end
if ~isempty(strList)
    strList(end) = [];  
end
end