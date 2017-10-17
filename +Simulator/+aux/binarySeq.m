function y = binarySeq(t,b,T)

% e  = eps*1e3;
e = mean(diff(t))/1000;
n =size(b,2);
% % % t_bb = zeros(1,(n+1)*2);
% % % t_bb(2:2:end)=e:T:(e+T*n);
% % % t_bb(1:2:end)=0:T:n*T;
% % % 
% % % bb=zeros(1,(n+1)*2);
% % % bb(2:2:end-1)=b;
% % % bb(3:2:end)=b;


t_bb = zeros(1,n*2);
t_bb(1:2:end) = (0:T:(n-1)*T);
t_bb(2:2:end) = (T:T:n*T)-e;
bb=zeros(size(b,1),n*2);
bb(:,1:2:end-1)=b;
bb(:,2:2:end)=b;


% if(t(1)<0)
%     t_bb = [t(1) t_bb];
%     bb = [0 bb];
% end
% 
% if(t(end)>n*T+e)
% t_bb(end+1)=t(end);
% bb(end+1)=0;
% end


y = interp1(t_bb,bb',t,'linear',0)';



end