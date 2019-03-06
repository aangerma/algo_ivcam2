classdef ADB<handle
    properties (Access=private)
        m_adbexe
    end
    
    methods (Access=private)
        function im=privGetImageFile(obj,remoteImgfn)
            tempimpath=strrep(tempdir,'\','/');
            obj.cmd('pull /mnt/sdcard/dcim/Camera/%s %s',remoteImgfn,tempimpath);
            im = imread(sprintf('%s%s',tempimpath,remoteImgfn));
        end
        
    end
    methods (Access=public)
        
        function [val,res] = cmd(obj,varargin)
            str = sprintf(varargin{:});
            cmd = sprintf('%s %s',obj.m_adbexe,str);
            [res,val]=system(cmd);
        end
        
        function [val,res] = shell(obj,varargin)
            str = sprintf(varargin{:});
            [val,res]=obj.cmd('shell "%s"',str);
            val = strtrim(val);%remove ws;
        end
        
        %destructor
        function delete(obj)
            obj.cmd('adb kill-server');
        end
        
        function obj = ADB()
            obj.m_adbexe=fullfile(fileparts(mfilename('fullpath')),filesep,'adb.exe');
            [val,ok]=obj.cmd('start-server');%#ok
        end
        
        function im=getCameraFrame(obj)
            remoteCamDir='mnt/sdcard/dcim/Camera';
            [lastimfn_,failed]=obj.shell('cd %s && ls -Art | tail -n 1',remoteCamDir);
            if(failed)
                error(lastimfn_);
            end
            obj.shell('am start -a android.media.action.STILL_IMAGE_CAMERA');
            obj.shell('input keyevent KEYCODE_FOCUS');
            pause(1);
            obj.shell('input keyevent KEYCODE_CAMERA');
            pause(0.5);
            lastimfn=obj.shell('cd %s && ls -Art | tail -n 1',remoteCamDir);
            if(isequal(lastimfn,lastimfn_))
                im=[];
                warning('Failed to get camera frame');
            else
            im=obj.privGetImageFile(lastimfn);
            obj.shell('rm %s/%s',remoteCamDir,lastimfn);
            end
            
            
        end
        
        
    end
    
    
    
end