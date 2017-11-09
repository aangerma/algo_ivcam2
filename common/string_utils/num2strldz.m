function numStrLDZ = num2strldz(num, numLength)
%NUM2STRLDZ - integer number to string of a given length, using leading zeros
%        NUMLDZ = NUM2STRLDZ(NUM, NUMLENGTH) NUMLDZ is a string of length
%        NUMLENGTH containing the (integer) number NUM. If NUM is shorter
%        than NUMLENGTH it adds leading zeros.

% Saki 07/07

if nargin==1
    numLength = 3;
end
numZeros = num2str(numLength);
eval(['numStrLDZ = sprintf(''%0.', numZeros,'d'', num);']);

    
