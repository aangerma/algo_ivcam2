function [values] = sampleByMask(I,binMask)
    % Extract values from image I using the binMask with the order being
    % row and then column
    I = I';
    values = I(binMask');
        
end 