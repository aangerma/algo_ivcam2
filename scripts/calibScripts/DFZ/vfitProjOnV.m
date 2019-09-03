function [vnew] = vfitProjOnV(v,vfit)

vnew = sum(vfit.*v,2) .* v./sum(v.^2,2);

%{
%     Degug plot:
figure;
for  k =1:size(v,1)
    plot3([0 v(k,1)],[0 v(k,2)],[0 v(k,3)] ,'b','LineWidth', 2);  hold on;
    plot3([0 vfit(k,1)],[0 vfit(k,2)],[0 vfit(k,3)], 'r','LineWidth', 2);
    plot3([v(k,1) vfit(k,1)],[v(k,2) vfit(k,2)],[v(k,3) vfit(k,3)], 'g','LineWidth', 2);
    plot3([0 vnew(k,1)],[0 vnew(k,2)],[0 vnew(k,3)], '--c','LineWidth', 2);
end
grid minor;
%}
end

