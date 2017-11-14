function [v f] = objread(fn)
%from http://people.csail.mit.edu/sumner/research/deftransfer/data.html#download
fid = fopen(fn,'r');
v=[];
f=[];
while ~feof(fid)
    line = fgets(fid); %# read line by line
    if(isempty(line))
        continue;
    end
    if(line(2)=='n')
        continue;
    end
    switch(line(1))
        case 'v'
            v(end+1,:)=str2num(line(2:end));%#ok;
        case 'f'
            lll=str2num(strrep(line(2:end),'//',' '));%#ok
            f(end+1,:)=lll(1:2:end);%#ok
    end
end
fclose(fid);
% meshxyz = zeros(size(f,1),3,3);
% for i=1:size(f,1)
%     meshxyz(i,:,:) = v(f(i,:),:)';
% end
% trisurf(f,v(:,1),v(:,2),v(:,3));axis equal
end