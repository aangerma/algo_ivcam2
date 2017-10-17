function ivs = readIVS( filename )
[~,~,ext]=fileparts(filename );
if(~strcmpi(ext,'.ivs'))
    error('file extention is not IVS');
end
lut=typecast(vec(flipud(int8((dec2bin((0:255)')-48)~=0)')),'uint64');
fid = fopen(filename, 'rb');
if (fid == -1)
    error('Cannot open file for reading');
end
readstream = uint8(fread(fid,'uint8'));
fclose(fid);
if(mod(length(readstream),8)~=0)
    error('Bad ivs length');
end
readstream = typecast(readstream,'uint64');
if(mod(length(readstream),2)~=0)
    error('Bad ivs length');
end

readstream = reshape(readstream,2,[]);


ivs.fast = (typecast(lut(uint16(typecast(readstream(1,:),'uint8'))+1),'uint8')~=0)';


slow_xy_flags = reshape(typecast(readstream(2,:),'uint16'),4,[]);

ivs.slow = slow_xy_flags(1,:);
ivs.xy = reshape(typecast(vec(slow_xy_flags(2:3,:)),'int16'),2,[]);
ivs.flags = uint8(slow_xy_flags(4,:));
assert(max(ivs.slow(:))<2^12,'slow data should be 12 bit');
assert(max(ivs.flags(:))<2^5,'flags data should be 5 bit');
% assert(all(ivs.xy(:)<=2^11-1 &  ivs.xy(:)>=-2^11),'xy data should be 12 bit');

end