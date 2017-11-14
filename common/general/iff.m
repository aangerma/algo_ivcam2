function varargout =  iff(varargin)
%usage: 1. iff(true/false,val if true,val if false)
%       1. iff(numeric,return if 1,return if 2,...)
cond = varargin{1};
if(islogical(cond))
    cond = 3-cond;
else
    cond = cond+1;
end
varargout{:} =  varargin{cond};

end