function [vC,triC,colorC]=concatenateTriVert(varargin)

if( nargin == 4 )
     vA = varargin{1};
     triA = varargin{2};
     vB = varargin{3};
     triB = varargin{4};
    colorC = [];
elseif( nargin == 6 )    
     vA = varargin{1};
     triA = varargin{2};
     colorA = varargin{3};
     vB = varargin{4};
     triB = varargin{5};
     colorB = varargin{6};
     colorC = [colorA;colorB];
end

vC = [vA;vB];
triC = [triA;triB+size(vA,1)];

end