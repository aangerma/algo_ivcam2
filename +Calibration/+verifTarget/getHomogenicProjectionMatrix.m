function H = getHomogenicProjectionMatrix( inputPoints, projectedPoints )
%(a b c)*(x) = (x')
%(d e f) (y)   (y')
%(g h 1) (1)   (z')
%
%xr = x'/z' ; yr = y'/z';
%
%  ------->
%
%[...                    ]         (...) 
%[x y 1 0 0 0 -xr*x -xr*y]*(a  ) = (xr )
%[0 0 0 x y 1 -yr*x -yr*y] (...)   (yr )
%[...                    ] (h  )   (...)                 


numPoints = size(inputPoints,1);

A = zeros(2*numPoints,8);b=zeros(8,1);
for i=1:numPoints
    x = inputPoints(i,1);
    y = inputPoints(i,2);
    xr = projectedPoints(i,1);
    yr = projectedPoints(i,2);
    
    A(2*(i-1)+1,:) = [x y 1 0 0 0 -xr*x -xr*y];
    A(2*i,:) =       [0 0 0 x y 1 -yr*x -yr*y];
    
    b(2*(i-1)+1) = xr;
    b(2*i) =  yr;
end
h = A\b;
H = reshape( [h;1],3,3)';
end

