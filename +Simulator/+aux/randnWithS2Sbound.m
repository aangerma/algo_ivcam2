function v=randnWithS2Sbound(n,s,bound)

v = randn(n,1)*s;
if(s>0 && bound>0)
    for i=1:200
        v = v/std(v)*s;
        for j=1:200
            violantion = find(abs([false;diff(v)])>bound,1);
            if(isempty(violantion))
                break;
            end
            v(violantion)= randn()*s;
        end
        
    end
    if(abs(std(v)-s)/s>0.01)
        warning('bound is too low, consider raising, or lowering sigma. targetRMS=%gnsec, outputRMS=%gnsec',s,std(v))
    end
    
end

end