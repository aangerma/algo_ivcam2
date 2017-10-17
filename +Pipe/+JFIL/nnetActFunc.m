function [out] = nnetActFunc(in, v,fastApprox)

biases = v(7:12);
slopes = v(1:6);


index = floor(max(-1,min(1,in))*3+3);
index = min(index,5);%data should be [0-5], value of 6 should not axist as data is withthin [-1:1)
if(fastApprox)
    out = in.*slopes(index+1)+biases(index+1);
else
    out = Utils.fp20('mul',in,slopes(index+1));
    out = Utils.fp20('plus',out,biases(index+1));
end


end