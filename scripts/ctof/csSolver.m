function xout =csSolver(sensmat,mes,varargin)
p=parseInput(varargin);
switch(p.method)
    case 'lp'
        xout = solve_linearProgramming(sensmat,mes,p);
end
end

function xout = solve_linearProgramming(sensmat,mes,p)

end

function arg=parseInput(varargin)
inp = inputParser;

inp.addOptional('method','lp');
inp.addOptional('tol',1e-3);
inp.parse(fn,x,y,z,varargin{:});
arg = inp.Results;
clear('inp');
end
