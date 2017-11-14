function [vertex, face] = wrlread(filename)
txt = fileread(filename);
res = regexp(txt,'point \[(?<pts>[^\]]+)\]\s*\}\s*coordIndex\s*\[(?<indx>[^\]]+)\]','names');
vertex=[];
face =[];
for i=2:length(res)
    verI = str2num(res(i).pts);
    if(isempty(verI))
        continue;
    end
    faceI = str2num(res(i).indx);
    indx = size(vertex,1);
    vertex(indx+(1:size(verI,1)),:)=verI;
    face(end+(1:size(faceI,1)),:)=indx+faceI(:,1:3);
end
face=face+1;
    end