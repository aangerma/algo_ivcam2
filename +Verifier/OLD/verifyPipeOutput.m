function  vStruct=verifyPipeOutput(pipeOutData,fn,outputdir)

[tb,te] = regexp(fn,'(?<d>[\d]+)');
dist = str2double(fn(tb(1):te(1)));
chartType = fn(te(1)+1:end);
chartType=strtrim(chartType);
if(chartType(1)=='_')
    chartType=chartType(2:end);
end

% open verifier session
adoConnection = Verifier.getVerifier();

vStruct = struct;
% new sessionID
sessionType = 'TEST';
PipeVersion = 1;%Pipe.version;
timestamp = datetime;


%zbin & Ibin - bin file to hex string

files = dir(outputdir);
files = {files.name};

ifn = files{~cellfun(@isempty,strfind(files,[fn '.bini']))} ;
Ibin = SQL.bin2varbinary([outputdir ifn],'uint8');
zfn = files{~cellfun(@isempty,strfind(files,[fn '.binz']))};
Zbin = SQL.bin2varbinary([outputdir zfn],'uint8');


columns = {'StartTime','ChartType','Distance','SwVersion','SessionType','UserName','Ibin','Zbin'};
values = {datestr(timestamp),chartType,dist,PipeVersion,sessionType,getenv('username'),Ibin,Zbin};
output = 'SessionID';

[sqlString] = SQL.sqlInsert('SESSION',columns,values,output);
[instrtedPK] = adodb_query(adoConnection, sqlString);
mySessionID = uint16(instrtedPK(1).sessionid);
% 
% % DRAS Verify
% vStruct = Verifier.verifyDRAS(pipeOutData,adoConnection,mySessionID,vStruct);
% 
% 
% % DCOR Verify
% cor2verifier.corrOffset = pipeOutData.corrOffset;
% cor2verifier.corr = pipeOutData.corr;
% cor2verifier.cImg = pipeOutData.cImg;
% vStruct = Verifier.verifyDCOR(cor2verifier,adoConnection,mySessionID,vStruct);


blob = SQL.image2blob(single(pipeOutData.iImg),[16 16]);
[addBlob] = SQL.sqlUpdateWhere('SESSION',{'ImageBlob'},{blob},'SessionID',mySessionID);
adodb_query(adoConnection, addBlob);


[closeSession] = SQL.sqlUpdateWhere('SESSION',{'EndTime','ErrorCode'},{datestr(datetime),0},'SessionID',mySessionID);
adodb_query(adoConnection, closeSession);
end