function [ OUT ] = OpenFile( File,Width,Height,Bpp,Type,debug  )

if(nargin<6)
    debug=0;
end

t=1;
if debug
    fprintf('trying to open file %s\n ' ,File);
end

while t<6
    try
        msg=strcat('trying to open file, t= ',num2str(t),'\n');
        if debug
            fprintf(msg);
        end
        f = fopen(File,'r');
        if(f~=-1)
            if Bpp==1
                OUT = fread(f,[Width,Height],Type)';
            elseif Bpp==inf
                OUT = fread(f,inf,Type)';
                
            else
                OUT = fread(f,Width*Height*Bpp,Type)';
            end
            
            fclose (f);
            msg=strcat('Succeed in t= ',num2str(t),'\n');
            if debug
                fprintf(msg);
            end
            
            break;
        end
    catch e
        fprintf(strcat(e.message,'(t=%d)\n'),t);
        if(f~=-1)
            fclose (f);
        end
        if (t==5)
            msg=strcat('Failed to open file: ',File,'\n');
            if debug
                msg
            end
            OUT=nan;
            return;
        end
        continue;
    end
    t=t+1;
end
if (t==6)
    msg=strcat('Failed to open file: ',File)
    
    OUT=nan;
    return;
end


end


