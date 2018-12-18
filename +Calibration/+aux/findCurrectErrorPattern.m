function  pattern = findCurrectErrorPattern(patterns,string)
    pattern = [];
    for i=1:length(patterns)
        if ~isempty(strfind(string,patterns{i}))
            pattern = patterns{i};
            break;
        end
    end
end