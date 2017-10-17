function [ output ] = applyGamma(  input,nInBits, lut,nOutBits, scale, offset )
%GAMMA apply a gamma function on the input
% numberOfEntryBits :  How many bits we are going INto the LUT
% numberOfExitBits : How many bits are we going OUT of the LUT with
    sampVal = bitshift(int64(input)*int64(scale(1)),-10)+int64(offset(1)); % The output from this line is 19 bits signed, and we want to force this to be a non negative number
    sampVal = max(0,sampVal); % This line enforces non-negativity.
    sampVal = min(sampVal,2^nInBits-1); %reduce to nInputbits LSBs with saturation. 
    lutobj = LUTi(uint64(lut),nOutBits); % Access to a linear interpolation LUT
    output = lutobj.at(sampVal,nInBits); % 
    output = bitshift(int64(output)*int64(scale(2)),-10) + int64(offset(2));
    output = max(0, output); % This line enforces non-negativity.
    output = min(output,2^nInBits-1); %reduce to nInputbits LSBs with saturation. 

    output = uint64(output); 
end

