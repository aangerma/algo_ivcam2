function [regs] = readAlgoEpromData(obj,BinData,EPROMstructure)
% BinData: eprom Bin data array with no header
if(~exist('EPROMstructure','var'))
    current_dir = mfilename('fullpath');
    ix = strfind(current_dir, '\');
    path = fullfile(current_dir(1:ix(end-1)-1), '\+Calibration\eepromStructure\eepromStructure.mat');
     
    EPROMstructure=load(path); EPROMstructure=EPROMstructure.updatedEpromTable; 
end
%%
s = Stream(BinData);
readEprom=EPROMstructure;
for i=1:length(EPROMstructure)
    si=EPROMstructure(i);
    type=si.type;
    
    switch type
        case {'uint32'}
            val=s.getNextUint32();
        case {'int32'}
            val=s.getNextInt32();
            val=typecast(val,'uint32');
        case {'single'}
            val=s.getNextSingle();
        case {'uint16'}
            val=s.getNextUint16();
        case {'int16'}
            val=s.getNextInt16();
            val=typecast(val,'uint16');
        case {'logical'}
            val=s.getNext();
        otherwise
            error('undifiend type');
    end
    if(strcmp(type,'single'))
        valHex=single2hex(val);
    else
        valHex=dec2hex(val);
    end
    readEprom(i).base='h';
    readEprom(i).value=valHex;
    
    readEprom(i).valueUINT32 = obj.sprivRegstruct2uint32val(si);
end

%% create struct try to use the origin
regs=obj.sprivRmData2struct(readEprom);

end

function d=readbin(fn)
fid = fopen(fn,'r');
d=uint8(fread(fid,'uint8'));
fclose(fid);
end




