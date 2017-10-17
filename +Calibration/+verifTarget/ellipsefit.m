function report=ellipsefit(X,Y)
%ELLIPSEFIT - form 2D ellipse fit to given x,y data
%in:
% X,Y: Input vectors of 2D coordinates to be fit.
%out:
% Finds the ellipse fitting the input data parametrized both as:
% A'*x^2+B'*x*y+C'*y^2+D'*x+E'*y=1
% and
% [x-x0,y-y0]*Q'*[x-x0;y-y0]=1


% what is Q':
% [x,y]*Q'*[x;y] = 1  -svd-> [x,y]*U*S*V'*[x;y] = 1  -U=V because of symmetry->
% (X'*U*sqrt(S))*((sqrt(S)*V'*X) = 1 -->  ((sqrt(S)*V'*X)'*((sqrt(S)*V'*X) = 1 -->
% ((sqrt(S)*V'*X) = (x/r y/r) because (x^2 + y^2)/(r^2) = 1


% report: a structure output with the following fields
%
%    report.Q: the matrix Q
%    report.d: the vector [x0,y0]
%    report.ABCDE: the vector [A,B,C,D,E]
%    report.AxesDiams: The minor and major ellipse diameters
%    report.theta: The counter-clockwise rotation of the ellipse.
%
%NOTE: The code will give errors if the data fit traces out a non-elliptic or
%      degenerate conic section.


%% find fit
for i=1:3
    
    %find fit ABCDEF
    X=vec(X);
    Y=vec(Y);
    M= [X.^2, X.*Y, Y.^2, X, Y, -ones(size(X,1),1)];
    [U,S,V]=svd(M,0);
    ABCDEF=V(:,end);
    if size(ABCDEF,2)>1
        error 'Data cannot be fit with unique ellipse'
    end
    
    %remove outliers and repeat
    err = M*ABCDEF;
    delta = 5;
    margins = prctile(err,[delta 100-delta]);
    inliers = err>=margins(1) & err<=margins(2);
    X = X(inliers);
    Y = Y(inliers);
end


ABCDEF=num2cell(ABCDEF);
[A,B,C,D,E,F]=deal(ABCDEF{:});


%% ===find both parametrizations===
%given:  A*x^2+B*x*y+C*y^2+D*x+E*y=F  -->
%[x y][A    0.5B][x] + [x y][D] = F
%     [0.5B C   ][y]        [E]
%
%denote
% Q = [A    0.5B]
%     [0.5B C   ]
%
% res1: [A', B', C', D', E'] = [A, B, C, D, E]/F;
%
% res2:
% [x-x0,y-y0]*Q*[x-x0;y-y0]=f --> Q/f == Q' --> need to find f -->
%
% [x,y]*Q*[x;y] + [x0,y0]*Q*[x0;y0] -2*[x,y]*Q*[x0;y0] = f  -->
%
% 1. find [x0, y0]:
% [x y][D; E] = -2*[x y]*Q*[x0;y0] --> -0.5*inv(Q)*[D; E] == [x0; y0];
%
% 2. find f:
% f - [x0,y0]*Q*[x0;y0] = F --> F + [x0,y0]*Q*[x0;y0] = f;
%

Q=[A, B/2;B/2 C];
x0=-Q\[D;E]/2;
dd=F+x0'*Q*x0;
Q=Q/dd;


% % % %% find axis length and rotation angle
% % % [R,eigen]=eig(Q);
% % % eigen=eigen([1,4]);
% % % if ~all(eigen>=0), error 'Fit produced a non-elliptic conic section'; end
% % % idx=eigen>0;
% % % eigen(idx)=1./eigen(idx);
% % % AxesDiams = 2*sqrt(eigen);
% % % theta=atand(tand(-atan2(R(1),R(2))*180/pi));


%% find transformation matrix- ellipse to circle
[u,s,v] = svd(Q);
%v' will rotate so the the ellipse axis will be parrale to actual axis,
%sqrt(s)/sqrt(s(1)) will normalize both axis to the same length
%u will rotate the circle back so the image will stay the same
T22 = u*sqrt(s)/sqrt(s(1))*v';
T = zeros(3);
T(3,3)=1;
T(1:2,1:2) = T22;


%% res
report.T = T;
report.Q=Q;
report.d=x0(:).';
report.ABCDE=[A, B, C, D, E]/F;
% % % report.AxesDiams=sort(AxesDiams(:)).';
% % % report.theta=theta;
end