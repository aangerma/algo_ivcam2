function extrm=findBinaryVectorTransitions(x,v,thr)
v1 = gradient(v);
v2=gradient(v1);
[~,d]=crossing(v2);
extrm = d(abs(vectAtLinear(x,v1,d))>thr);
end