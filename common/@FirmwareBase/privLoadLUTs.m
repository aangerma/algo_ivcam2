function [ obj ] = privLoadLUTs( obj )
    lutdata = FirmwareBase.sprivReadCSV([obj.m_tablesFolder filesep 'lutsDefinitions.frmw']);
    headers = strtrim(lutdata(1,:));
    if(~all(strcmpi(headers,{'lutName'    'length'    'elemSize' 'address'  })))
        error('LUT header should be lutName    length    elemSize ');
    end
    lutdata =lutdata(2:end,:);
    
    evltxt=sprintf('headers{%d},lutdata(:,%d),',[1:length(headers);1:length(headers)]);
    evltxt=sprintf('struct(%s)',evltxt(1:end-1));
    obj.m_luts=eval(evltxt);

    
    
    for i=1:length(obj.m_luts)
        blkLutName = lutdata{i,1};
        fn = fullfile(obj.m_tablesFolder,filesep,['LUTs' filesep blkLutName '.lut']);
        if(exist(fn,'file'))
            obj.m_luts(i).data = realLUT(fn);
        else
             obj.m_luts(i).data = uint32(zeros(1,str2double(obj.m_luts(i).length)));%just to know the size...  no metter the type- it will change in 'setLut'
        end
        [obj.m_luts(i).algoBlock,obj.m_luts(i).algoName,~]=FirmwareBase.sprivConvertRegName2blockNameId(blkLutName);
        
        if(max(obj.m_luts(i).data)>2^str2double(obj.m_luts(i).elemSize)-1)
            error('LUT Max value is not consistent with elemSize (%s)',blkLutName);
        end
        if(str2double(obj.m_luts(i).length)~=length(obj.m_luts(i).data))
             error('LUT length value is not consistent data length(%s)',blkLutName);
        end

        obj.m_luts(i).elemSize=str2double(obj.m_luts(i).elemSize);
        obj.m_luts(i).address=str2double(obj.m_luts(i).address);
    end
    
    obj.m_luts=rmfield(obj.m_luts,'length');
    
    
end


function z=realLUT(fn)
z=cellfun(@(x) hex2dec(strtrim(x)),str2cell(fileread(fn),10),'uni',false);
z = [z{:}];
z = uint32(z);
end

