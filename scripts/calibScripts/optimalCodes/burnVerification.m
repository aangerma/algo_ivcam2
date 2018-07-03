function burnVerification(hw,mwdfn,valmwdfn)

% Read from mwd file
filters = {'EPT';'MTLB';'FRMW';'EPTG';'STAT';'EXTLcorSaturationPrc'};
fid = fopen(mwdfn);
fileID = fopen(valmwdfn,'w');
tline = fgetl(fid);
while ischar(tline)
    regName = tline(35:end);
    validReg = true;
    for f = 1:numel(filters)
        validReg = validReg && isempty(strfind(regName,filters{f})==1);
    end
    if ~validReg
        fprintf(fileID,[tline,'\n']);
        tline = fgetl(fid);
        continue;
    end
        
    tline(2) = 'r';
    fprintf([tline,'\n']);
    [~,devVal] = hw.cmd(tline);
    tline(2) = 'w';
    tline(23:30) = sprintf('%08x',devVal);
    fprintf(fileID,[tline,'\n']);
    tline = fgetl(fid);
end
fclose(fid);
fclose(fileID);
end
% hw.burn2device('c:\temp\TT\',1,1);
% m = fw.getMeta();
% % Read all regs
% fileID = fopen('currRegs5.txt','w');
% for i = 1:numel(m)
%     if isempty(strfind(m(i).regName,'EPT')) && isempty(strfind(m(i).regName,'MTLB')) && isempty(strfind(m(i).regName,'FRMW')) && isempty(strfind(m(i).regName,'EPTG')) && isempty(strfind(m(i).regName,'STAT')) && isempty(strfind(m(i).regName,'EXTLcorSaturationPrc'))
%        fprintf('Collected: %d %s\n',i,m(i).regName);
%        [~,devVal] = hw.cmd(sprintf('mrd %08x %08x',m(i).address(1),m(i).address(1)+4) );
%        str = sprintf('mwd %08x %08x %08x // %s\n',m(i).address(1),m(i).address(1)+4,devVal,m(i).regName);
%        fprintf(fileID,str);
%     else
%        fprintf('Skipped: %d %s\n',i,m(i).regName);
%     end
% end
% fclose(fileID);
