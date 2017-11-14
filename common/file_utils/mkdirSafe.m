function mkdirSafe(d)
if(~exist(d,'dir'))
    mkdir(d);
end
end
