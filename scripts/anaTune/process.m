f = dirRecursive('d:\ohad\data\lidar\EXP\20170613_anatune\ext\','record_01.ivs');
i=1;
ca=[];
%%
for i=1:length(f)
ivs=io.readIVS(f{i});
txt=fileread(fullfile(fileparts(f{i}),'configuration.txt'));
c=regexp(txt,'(?<n>[^=]+)=(?<v>[^\n]+)\n','names');
cn = {c.n};
cn = regexprep(strtrim(cn),'/|\s','_');
c = cell2struct(strtrim({c.v}),cn,2);
c.ivs=ivs;


sdf=double(bitget(ivs.flags,3));
sdf(1:find(sdf==0,1))=0;
sdf(find(sdf==0,1,'last'):end)=0;
sdf_r = find(diff(sdf)==1);
sdf_f = find(diff(sdf)==-1);
e = vec([sdf_r;sdf_f]);
sl=arrayfun(@(x) [ivs.xy(2,e(x):e(x+1));ivs.slow(e(x):e(x+1))],1:length(e)-1,'uni',0);

ang2pixScale = 4;
slI=cellfun(@(x) accumarray(round((2047+double(x(1,:))')/ang2pixScale),double(x(2,:))',[4096/ang2pixScale 1],@mean,nan),sl,'uni',0);
slI = [slI{:}];
slim=slI(:,1:2:end);
%
yg=1:size(slim,1);
slimI=arrayfun(@(x) interp1(yg(~isnan(slim(:,x))),slim(~isnan(slim(:,x)),x),yg)',1:size(slim,2),'uni',0);
slimI=[slimI{:}];

% ylims = any(isnan(slimI) | slimI==0,2);
% ylims=find(ylims==0,1)+1:find(ylims==0,1,'last')-1;
c.slimI=slimI;
c.slm=mean(slimI,2);
% slm(slm==0)=nan;
c.sls=nanstd(slimI,[],2);
ca = [ca c];
disp(i)
end
%%
flds = {'TIA_HPF','Ampdet_curve','X0_LPF_Pole','LPF_Cutoff'};
fldsVals = cell(size(flds));
for i=1:length(flds)
    fldsVals{i} = unique({ca.(flds{i})});
end
%

for i=1:length(flds)
newKeys = arrayfun(@(jj) {ca.(flds{jj})},setdiff(1:length(flds),i),'uni',0);newKeys=strcat(newKeys{:});

keyIindx=find(strcmp(cellmode(newKeys),newKeys));

keYkeys=arrayfun(@(jj) {ca(keyIindx).(flds{jj})},1:length(flds),'uni',0);keYkeys = strcat(keYkeys{:})';
keYkeysU=unique(keYkeys);
indexI=keyIindx(cellfun(@(S) find(strcmp(keYkeys,S),1),keYkeysU));
% zz =cellfun(@(x) x(find(~isnan(x),1):find(~isnan(x),1,'last')),{ca(indexI).slm},'uni',0);
% zz = cellfun(@(x) [x;zeros(4096-length(x),1)],zz,'uni',0);
% zz=[zz{:}];
zz=[ca(indexI).slm];

figure(i);
plot(zz)
legendKeys=arrayfun(@(jj) strcat({ca(indexI).(flds{jj})},'\_\_'),1:length(flds),'uni',0);legendKeys = strcat(legendKeys{:})';
legend(legendKeys);
title(strrep(flds{i},'_',' '));
end
