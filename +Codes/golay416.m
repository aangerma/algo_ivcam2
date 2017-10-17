function [tx,ker,c] = golay416(space)

if(~exist('space','var'))
   space =10;  % the spacing between the pulses
end

s1= -1+2*[0 0 0 1 1 0 0 0 1 0 1 1 0 1 0 1 0 1 1 0 0 1 0 0 0 0];
s2= -1+2*[0 0 0 0 1 0 0 1 1 0 1 0 0 0 0 0 1 0 1 1 1 0 0 1 1 1];

s12=[s1 s2];
s21=[s1 -s2];

s13=[s12 s21];
s31=[s12 -s21];

s14=[s13 s31];
s41=[s13 -s31];

s15=[s14 s41];
s51=[s14 -s41];

ssig(1,:)=s15>0;
ssig(2,:)=s51>0;

mm=1; % number of samples per manchester bit

sp=[ ];

sig1=[ 1 sp 0 sp]; % transmitted "1"
sig0=[ 0 sp 1 sp]; % transmitted "0"

ref1=[ 1 sp -1 sp]; % reference "1"
ref0=[ -1 sp  1 sp]; % reference "0"




%  manchester coding of signal and matched reference

for p=1:2
    
    codem=ssig(p,:);
    
    matched_ref=ones(size(codem));
    lc=length(codem);
    
    sig=[ ];
    ref=[ ];
    for q=1:lc
        if codem(q)==1
            sig=[sig sig1];
            ref=[ref   matched_ref(q)*ref1];
        else
            sig=[sig sig0];
            ref=[ref   matched_ref(q)*ref0];
        end
    end
    
    signal(p,:)=kron(sig,ones(1,mm));
    reference(p,:)=kron(ref,ones(1,mm));
    
%     out(p,:)=xcorr(signal(p,:), reference(p,:));
%     out_max(p)=max(out(p,:));
%     out(p,:)=out(p,:)./out_max(p);
end

% out_sum=sum(out);



tx=[signal(1,:) zeros(1, space) signal(2,:)];  %  <====== The transmitted pair
ker=[reference(1,:) zeros(1, space) reference(2,:)]; % <====  The reference pair

c=reshape(tx,[2 length(tx)/2]);
c=c(1,:)*2-1;

end