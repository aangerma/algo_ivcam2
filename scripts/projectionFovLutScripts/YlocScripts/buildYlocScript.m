load('X:\Users\hila\L515\projectionByRoiLut\scanDirDIFF\anlyzeYloc\dupTable\data.mat');
t1 = t1(2:end);
tv0Dec=uint16(t1');
tv0Dec=[tv0Dec ; 4095];
[V0TableValue]= calcTableVal(tv0Dec); 
V0TableValue=V0TableValue(1:end-3,:); 
tv1Dec=flip(tv0Dec(1:end-1));
tv1Dec=[tv1Dec ; 4095];
[V1TableValue]= calcTableVal(tv1Dec); 
V1TableValue=V1TableValue(1:end-3,:); 

%% write to txt file
fpath='X:\Users\hila\L515\projectionByRoiLut\scanDirDIFF\anlyzeYloc\dupTable\flipScanTABLE'; 
fileName='t2flip.txt'; 
fileID = fopen(fileName,'w');

start_add=hex2dec('0000');
% ws=''; 
for i=1:length(V0TableValue)
    end_add= start_add + 4;
    fprintf(fileID,'mwd 8500%04x 8500%04x %s\n',start_add,end_add,V0TableValue(i,:));
    start_add=end_add;
end
for i=1:223
    end_add= start_add + 4;
    fprintf(fileID,'mwd 8500%04x 8500%04x %s\n',start_add,end_add,'00000000');
    start_add=end_add;
end 
for i=1:length(V1TableValue)
    end_add= start_add + 4;
    fprintf(fileID,'mwd 8500%04x 8500%04x %s\n',start_add,end_add,V1TableValue(i,:));
    start_add=end_add;
end
for i=1:219
    end_add= start_add + 4;
    fprintf(fileID,'mwd 8500%04x 8500%04x %s\n',start_add,end_add,'00000000');
    start_add=end_add;
end 
fclose(fileID);
copyfile(fileName,fullfile(fpath,fileName),'f');

%%
function [TableValue]= calcTableVal(tableDec)
i = 1;
TableValue=[];
while (i < length(tableDec))
    locations_coding=zeros(1,4); bit47_1=zeros(1,4); bit811_1=zeros(1,4); bit1215_1=zeros(1,4); bit1619_1=zeros(1,4);
    for k=1:4
        if(i>length(tableDec))
            break;
        end
        A=tableDec(i);
        if A>255 % 8-16 bit
            [locations_coding(k),bit47_1(k),bit811_1(k),bit1215_1(k),bit1619_1(k)]=fill4bytes(A);
            i = i+1;
            continue;
        elseif A>15 % A - 8
            B=tableDec(i+1);
            if (B>255)
                [locations_coding(k),bit47_1(k),bit811_1(k),bit1215_1(k),bit1619_1(k)]=fill4bytes(A);
                i=i+1;
                continue;
            else
                [locations_coding(k),bit47_1(k),bit811_1(k),bit1215_1(k),bit1619_1(k)]=fill2bytes(A,B);
                i=i+2;
                continue;
            end
        else % A 4 bit
            B=tableDec(i+1);
            if (B>255)
                [locations_coding(k),bit47_1(k),bit811_1(k),bit1215_1(k),bit1619_1(k)]=fill4bytes(A);
                i=i+1;
                continue;
            elseif B>15 % B 8 bit
                [locations_coding(k),bit47_1(k),bit811_1(k),bit1215_1(k),bit1619_1(k)]=fill2bytes(A,B);
                i=i+2;
                continue;
            else % B 4 bit
                C=tableDec(i+2);
                D=tableDec(i+3);
                if (C<16 && D<16)
                    [locations_coding(k),bit47_1(k),bit811_1(k),bit1215_1(k),bit1619_1(k)]=fill1bytes(A,B,C,D);
                    i=i+4;
                    continue;
                else
                    [locations_coding(k),bit47_1(k),bit811_1(k),bit1215_1(k),bit1619_1(k)]=fill2bytes(A,B);
                    i=i+2;
                    continue;
                end
            end
        end
        
    end
    setByte={}; 
    for r=1:4
        setByte{r} = fliplr([bit47_1(r) bit811_1(r) bit1215_1(r) bit1619_1(r)]) ;
    end

   
    Byte1 = dec2hex(locations_coding(1) + (bitshift(locations_coding(2),2))) ;
    Byte2 = dec2hex(locations_coding(3) + (bitshift(locations_coding(4),2))) ;
    % [num2str(Byte1),setByte{1:2}, num2str(Byte2) ,setByte{3:4}]
    t=['0000000000',setByte{4},setByte{3},Byte2,'0000',setByte{2},setByte{1},Byte1];
    TableValue=[TableValue ; flipud(reshape(t,8,[])')];
    
end
end

function [locations_coding,first_byte,second_byte,third_byte,fourth_byte]=fill4bytes(num)
locations_coding=0;
first_byte=dec2hex(bitand(num,15)); % 0xf
second_byte=dec2hex(bitshift(bitand(num,240),-4)); %0xf0 >> 4
third_byte=dec2hex(bitshift(bitand(num,3840),-8)); %0xf00 >> 8
fourth_byte=dec2hex(bitshift(bitand(num,61440),-12)); %0xf000 >> 12
end

function [locations_coding,first_byte,second_byte,third_byte,fourth_byte]=fill2bytes(num1,num2)
locations_coding=1;
first_byte=dec2hex(bitand(num1,15)); % 0xf
second_byte=dec2hex(bitshift(bitand(num1,240),-4)); %0xf0 >> 4
third_byte=dec2hex(bitand(num2,15)); % 0xf
fourth_byte=dec2hex(bitshift(bitand(num2,240),-4)); %0xf0 >> 4
end
function [locations_coding,first_byte,second_byte,third_byte,fourth_byte]=fill1bytes(num1,num2,num3,num4)
locations_coding=2;
first_byte=dec2hex(bitand(num1,15)); % 0xf
second_byte=dec2hex(bitand(num2,15)); % 0xf
third_byte=dec2hex(bitand(num3,15)); % 0xf
fourth_byte=dec2hex(bitand(num4,15)); % 0xf
end