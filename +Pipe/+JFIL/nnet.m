function nout = nnet(fv,w,ns,functionVector,fastApprox)

fv = Utils.fp20('to',fv);
w = Utils.fp20('to',w);
functionVector = Utils.fp20('to',functionVector);


nLayers = length(ns)-1;
s=[prod([ns(1:end-1);ns(2:end)]) ns(2:end)];
ind = cumsum([0 s]);
nnData = arrayfun(@(i) w(ind(i)+1:ind(i+1)),1:length(ind)-1,'uni',0);
nn_A = arrayfun(@(i) reshape(nnData{i},ns(i:i+1)),1:nLayers,'uni',0);
nn_B = arrayfun(@(i) reshape(nnData{nLayers+i},ns(i+1),1),1:nLayers,'uni',0);
nout = fv;


for i=1:nLayers
    % nout_i = nout_i*A_i+B_i;
    if(fastApprox)
        nout = nn_A{i}'*nout;
        nout = bsxfun(@plus,nout,nn_B{i});
    else
        nout = Utils.fp20('dot',nout,nn_A{i})';
        nout = Utils.fp20('plus',nout,nn_B{i});
    end
%     if(i==nLayers)
%         %no activation on last layer
%         break;
%     end
    nout = Pipe.JFIL.nnetActFunc(nout, functionVector,fastApprox);
    
end
%out of range pixels should get a value of 0
badres = isnan(nout) | isinf(nout);
nout(badres)=0;
end



