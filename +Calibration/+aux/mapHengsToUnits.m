function mapHengsToUnits(outputFolder)

generalPath = '\\143.185.124.250\Tester-data\IDC Data\IVCAM\L515\Calibration\BIG PBS\';
hengFolders = dir([generalPath, 'heng*']);

unitSN = zeros(0,1);
unitData = struct('folder', cell(1,0));

if ~exist('outputFolder', 'var')
    outputFolder = '';
end

%%

tic
for iFldr = 1:length(hengFolders)
    fprintf('Mapping %s...\n', hengFolders(iFldr).name);
    innerFoldersLevel1 = dir([generalPath, filesep, hengFolders(iFldr).name]);
    innerFoldersLevel1 = innerFoldersLevel1(arrayfun(@(x) x.isdir && ~strcmp(x.name(1),'.'), innerFoldersLevel1));
    for iInner1 = 1:length(innerFoldersLevel1)
        SN = textToSerialNum(innerFoldersLevel1(iInner1).name);
        if ~isnan(SN)
            ind = find(unitSN==SN);
            if ~isempty(ind)
                unitData(ind).folder{end+1} = hengFolders(iFldr).name;
            else
                unitSN(end+1) = SN;
                unitData(end+1).folder = {hengFolders(iFldr).name};
            end
        else
            innerFoldersLevel2 = dir([generalPath, filesep, hengFolders(iFldr).name, filesep, innerFoldersLevel1(iInner1).name]);
            innerFoldersLevel2 = innerFoldersLevel2(arrayfun(@(x) x.isdir && ~strcmp(x.name(1),'.'), innerFoldersLevel2));
            for iInner2 = 1:length(innerFoldersLevel2)
                SN = textToSerialNum(innerFoldersLevel2(iInner2).name);
                if ~isnan(SN)
                    ind = find(unitSN==SN);
                    if ~isempty(ind)
                        unitData(ind).folder{end+1} = hengFolders(iFldr).name;
                    else
                        unitSN(end+1) = SN;
                        unitData(end+1).folder = {hengFolders(iFldr).name};
                    end
                end
            end
        end
    end
end
toc

save([outputFolder, 'hengs_to_units_mapping.mat'], 'unitSN', 'unitData')

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SN = textToSerialNum(txt)

SN = NaN;
if (length(txt)>=8)
    if any(strcmp(txt(1), {'F','f'}))
        SN = str2double(txt(2:8));
    end
end

end

