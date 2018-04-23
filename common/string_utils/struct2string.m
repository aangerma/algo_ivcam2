% function str = struct2string(s,equal_sign,delimiter)
%
% Transform struct to string that is a list of field=value (the delimiter and equal sign can be controlled).
function str = struct2string(s,equal_sign,delimiter)
        if ~exist('equal_sign','var')
                equal_sign = '=';
        end
        if ~exist('delimiter','var')
                delimiter = ' ';
        end                
        str = '';
        fn = fieldnames(s);
        delimiter_now = '';
        for i=1:length(fn)
                str = [str delimiter_now fn{i} equal_sign num2str(s.(fn{i}))];
                delimiter_now = delimiter;
        end
end

