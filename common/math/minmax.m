function varargout = minmax(v)
if(nargout<2)
    varargout{1}=[min(v(:)) max(v(:))];
else
    varargout{1} = min(v(:));
    varargout{2} = max(v(:));
end
end