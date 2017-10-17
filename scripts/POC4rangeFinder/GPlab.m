classdef GPlab < handle
    properties (Access=private)
        m_h
    end
    methods (Access=public)
        
        function delete(obj)
            if(~isempty(obj.m_h))
                GPlabInterface('delete',obj.m_h);
                obj.m_h=[];
            end
        end
        
        function obj = GPlab(gpMode,gpType,doAutoSkew,tmplLength,inDir,recOutDir)
            try
            obj.m_h=GPlabInterface('new',gpMode,gpType,doAutoSkew,tmplLength,inDir,recOutDir); %hardware
            catch e,
                error(e.message);
            end
        end
        function start(obj)
            GPlabInterface('start',obj.m_h);
        end
        
        function stop(obj)
            GPlabInterface('stop',obj.m_h);
        end
        function [fast,slow,xy,flags]=getFrame(obj)
            headerSize = 32;
            
            data=GPlabInterface('getFrame',obj.m_h);
            data=data(headerSize+1:end);
            data = buffer_(data,16);
            % fast = (vec(fliplr(dec2bin(vec(data(1:8,:)),8))')=='1')';
            
            fast=(vec(flipud(Firmware.dec2binFAST(typecast(vec(data(1:8,:)),'uint64'),64)))=='1')';
            
            slow =typecast(vec(data(9:10,:)),'uint16')';
            slow = uint16(2^12-1) - slow;
            x = typecast(vec(data(11:12,:)),'uint16')';
            y = typecast(vec(data(13:14,:)),'uint16')';
            flags = uint8(typecast(vec(data(15:16,:)),'uint16')');
            xy = [x;y];
        end
    end
end
