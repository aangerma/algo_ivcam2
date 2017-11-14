% Concrete singleton implementation
classdef Logger < handle
    properties (Access=private)
        m_verbose
        m_fileFid
    end
    
    
    
    methods (Access=public)
        
        function delete(obj)
            obj.close();
        end
        
        function obj = Logger(verbose,write2log,logfn)
            switch(nargin)
                case 0
                    verbose=false;
                    write2log=false;
                    logfn=-1;
                case 1
                    write2log=false;
                    logfn=-1;
                case 2
                    error('required log file name');
                case 3
                otherwise
                    error('Bad number of inputs');
                    
                    
            end
            
            obj.m_verbose=verbose;
            if(write2log)
                obj.m_fileFid=fopen(logfn,'w');
            else
                obj.m_fileFid=-1;
            end
        end
        
        function print(varargin)
            obj = varargin{1};
            if(obj.m_verbose)
                fprintf(varargin{2:end});
            end
            if(obj.m_fileFid~=-1)
                fprintf(obj.m_fileFid,varargin{2:end});
            end
        end
        
        function print2file(varargin)
            obj = varargin{1};
            if(obj.m_fileFid~=-1)
                fprintf(obj.m_fileFid,varargin{2:end});
            end
        end
        
        function error(varargin)
            %TODO
            % add opentoline in text
            %oo='<a href="matlab: opentoline(''D:\ohad\SOURCE\IVCAM\Algo\LIDAR\Scripts\POC4\POCanalyzer.m'',114,0)">line 114</a>'
            obj = varargin{1};
            callstack=dbstack;
            callstack = callstack(2:end);
            varargin{2}=[callstack(end).file '(line' num2str(callstack(end).line) '): ' varargin{2}];
            if(obj.m_fileFid~=-1)
                fprintf(obj.m_fileFid,varargin{2:end});
            end
            
            
            
            
            error(varargin{2:end});
            
            
        end
        
        
        function close(obj)
            if(obj.m_fileFid~=-1)
                fclose(obj.m_fileFid);
                obj.m_fileFid=-1;
            end
        end
        
        function disp(obj)
            fprintf('verbose:%d write2file:%d\n',obj.m_verbose,obj.m_fileFid~=-1);
        end
    end
    
    
    
    
end

