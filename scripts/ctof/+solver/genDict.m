function o = genDict(sz)
h=sz(1);
w=sz(2);
mat_dy=kron(eye(w),[zeros(h-1,1) eye(h-1)]-eye(h-1,h));
mat_dx=kron([zeros(w-1,1) eye(w-1,w-1)],eye(h))-kron(eye(w-1,w),eye(h));
o = [mat_dx;mat_dy];
% m=rand(h,w);
% assert(all(mat_dy*m(:)==vec(diff(m))) && all(mat_dx*m(:)==vec(diff(m,[],2))));
end