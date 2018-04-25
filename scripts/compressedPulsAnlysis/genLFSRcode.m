function genLFSRcode()
    %http://courses.cse.tamu.edu/walker/csce680/lfsr_table.pdf
 rng(1);
B=2; 
N=4;xorloc=[4 3];
N=5;xorloc=[5 3];
% N=6;xorloc=[6 5];
% N=10;xorloc=[10 7];

stateVec = randi(B,[N 1])-1;
circMat = circshift(eye(N),[-1 0]);

L=2^(N-1)-1;
v=zeros(L,1);
for i = 1:L
    stateVec=circMat*stateVec;
    xorvec=zeros(N,1);
    xorvec(xorloc-1)=stateVec(end);
    stateVec=mod(stateVec+xorvec+B,B);
    v(i)=stateVec(end);
end % for i
c=Utils.correlator(v,v*2-1);
    
    subplot(211);
    stem(v);
    subplot(212);
    stem(c);
    drawnow;
    
    
end
