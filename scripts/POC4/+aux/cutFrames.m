function frame=cutFrames(xy,dt,ind)
frame=cell(length(ind),1);
for i=1:length(ind)
    xyI=arrayfun(@(j) struct('angx',xy(1,ind{i}(j):ind{i}(j+1)-1), ...
                             'angy',xy(2,ind{i}(j):ind{i}(j+1)-1),...
                             't0',ind{i}(j)*dt       ),1:length(ind{i})-1,'uni',0);
    xyI=[xyI{:}];
%     for j=1:length(xyI)
%             xyI(j).angx = xyI(j).angx;
%             xyI(j).angy = xyI(j).angy;
%    end

    
    frame{i}=xyI;
    
    
end
end