function h = imagescNAN(varargin)
    nancolor = [0,0,0];
    isnancolor = find(strcmpi(varargin,'nancolor'));
    if any(isnancolor)
        nancolor = varargin{isnancolor+1};
        varargin(isnancolor+1) = [];
        varargin(isnancolor) = [];        
    end
    h = imagesc(varargin{1},varargin{2:end});
    %  setting alpha values
    if ismatrix( varargin{1} )
        set(h, 'AlphaData', ~isnan(varargin{1}))
    elseif ndims( varargin{1} ) == 3
        set(h, 'AlphaData', ~isnan(varargin{1}(:, :, 1)));
    end
    set(get(h,'parent'), 'color', nancolor);
end