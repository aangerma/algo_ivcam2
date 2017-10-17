function [quadSum] = sum_quads(IMG,RegsALSPixelSel)
    
    vec = @(x) x(:);
    % RegsALSPixelSel is a 4-bit registser, which in the quad to sum
    if RegsALSPixelSel==0
        quadSum=0;
        return;
    end
    
    RegsALSPixelSel = str2num(dec2bin(RegsALSPixelSel,4)')'; %#ok<ST2NM>
    
    
    quadStructure = [1 2;
                    3 4];
    [I,J] = find(quadStructure); I = 3-I; J = 3-J;
    quadImage = zeros(numel(IMG)/4,4);
    for k = 1:4
        quadImage(:,k) = vec(IMG(J(k):2:end,I(k):2:end));
    end
    
    % Output 32-bit
    quadSum = bitand(sum(vec(quadImage(:,find(RegsALSPixelSel)))),2^32-1);

end