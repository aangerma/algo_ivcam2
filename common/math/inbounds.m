function vout = inbounds(v,vminmax)
assert(length(vminmax)==2);
vout = v(v>vminmax(1) & v<vminmax(2));
end
