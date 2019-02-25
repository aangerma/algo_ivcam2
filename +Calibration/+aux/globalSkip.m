function [ value ] = globalSkip( set1read0,val )
global skipLddWarmUp;
if set1read0
    skipLddWarmUp = val;
else
    value = skipLddWarmUp;
end



end

