function lutOut = genJFILinvDepthConfidence()
t=0.5;
w = uint16(round(exp(-t*(1:15))*2^14));
%  fid=fopen('../JFILinvDepthConfidence.lut','w');
%   fprintf(fid,Utils.vec2lutData(w));
%  fclose(fid);


 lutOut.lut = w(:);
lutOut.name = 'JFILinvDepthConfidence';
end