function generateTestTarget(targetType,bg_margin,bg_width,bg_distance,varargin)

%{
example input:

generateTestTarget2('wlgrid',10,10,50,'thickness',90,...
    'outfn','d:\Yoni\test.stl','vectors','on',...
    'dist',50,'Num', 7, 'length_pole', 1000)

%}


%%%%%%%%%%%%%%%%%%%
%varargin parser:
%%%%%%%%%%%%%%%%%%%
default_thickness = 150;
default_distance = 50;
default_Num_rows = 10;
default_length_pole = 10;
default_fiducial_reflectivity = 0;

inp = inputParser;

inp.addRequired('targetType',@ischar);
inp.addRequired('bg_margin' );
inp.addRequired('bg_width' );
inp.addRequired('bg_distance' );

inp.addOptional('thickness', default_thickness, @(x)x > 0 && x < 10^2);
inp.addOptional('outfn', []);
inp.addOptional('dist',default_distance); %distance between each pole/cylinder
inp.addOptional('Num',default_Num_rows,@(x)x > 0);% Number of poles/cylinders/ each row/column = N*2+1
inp.addOptional('length_pole',default_length_pole,@(x)x > 0);%length of each pole
inp.addOptional('camera','on',@(x)strcmp(x,'on') || strcmp(x,'off') );%plot camera place
inp.addOptional('vectors','on',@(x)strcmp(x,'on') || strcmp(x,'off') );%plot vectors
inp.addOptional('fiducial',default_fiducial_reflectivity,@(x)x >= -1 && x<=100 );%add fiducials
inp.addOptional('axes_handle',[] );%where to plot

parse(inp,targetType,bg_margin,bg_width,bg_distance,varargin{:});
arg = inp.Results;


%because its is actually the num elemens in half row/col
arg.Num = floor((arg.Num-1)/2);



mdl = struct('vertices',[],'faces',[]);

cubeV = [0 0 0;       0 0 1;        0 1 0;        0 1 1;        1 0 0;        1 0 1;        1 1 0;        1 1 1;]-.5;
cubeF = [1 5 2;2 5 6;5 7 6;6 7 8;2 6 4;4 6 8;1 3 5;5 3 7;1 2 4;1 4 3;3 4 7;4 8 7];

%
N = 20;
cylndrV = [0 0 0;cos(2*pi*(0:1/N:1-1/N)') sin(2*pi*(0:1/N:1-1/N)') zeros(N,1);0 0 1;cos(2*pi*(0:1/N:1-1/N)') sin(2*pi*(0:1/N:1-1/N)') ones(N,1)];
cylndrF = [1+[zeros(1,N);2:N 1;1:N]';
    N+2+[zeros(1,N);1:N;2:N 1]';
    [N+1+([N+1 2:N]);N+1 2:N;2:N+1]'
    [N+2+(1:N);[3:N+1 2];N+2+(2:N) N+3]'
    ];

%


switch(targetType)
    case 'hsphere'      
        N = 600;
        [p,tri]=particleSampleSphere('N',N);
        ps  = p(tri(:,1),3)>0 & p(tri(:,2),3)>0 & p(tri(:,3),3)>0;
        mdl.faces = tri(ps,[1 3 2]);
        mdl.vertices = p*bg_distance;
        mdl.color = mdl.vertices(:,1)*0+255;
    case 'plane'
        mdl.vertices=zeros(1,3);
        mdl.faces=[];
        mdl.color = mdl.vertices(:,1)*0+255;
     case 'cylinders'
        D=round(arg.thickness/10);
        for x=-arg.Num:arg.Num
            for y=-arg.Num:arg.Num
                S = [D*abs(y)+D D*abs(y)+D D*abs(x)+D];
                T = [x*arg.dist y*arg.dist bg_distance-S(3)];
                cv = bsxfun(@plus,cylndrV*diag(S),T);
                [mdl.vertices,mdl.faces] =  concatenateTriVert(mdl.vertices,mdl.faces,cv,cylndrF);
            end
        end
        mdl.color = mdl.vertices(:,1)*0+255;
    case 'random'
        RRR = 20;
        for i=1:RRR
            R = rotation_matrix(rand*pi,rand*pi,rand*pi);
             R=eye(3);
            elemSize = bsxfun(@times,rand(1,3),[200 200 1000])+50;
            
            T = (rand(1,3)-.5)*800;
            T(3)=bg_distance;
            cv = bsxfun(@plus,(bsxfun(@plus,cubeV,[0 0 -.5]))*diag(elemSize)*R,T);
            [mdl.vertices,mdl.faces] =  concatenateTriVert(mdl.vertices,mdl.faces,cv,cubeF);
            
        end
         mdl.color = round(vec(repmat(rand(1,RRR),[size(cubeV,1),1]))*128+127);

    case 'poles'
        for x=-arg.Num:arg.Num
            for y=-arg.Num:arg.Num
                T = [x*arg.dist y*arg.dist bg_distance-arg.length_pole/2];
                cv = bsxfun(@plus,cubeV*diag([arg.thickness arg.thickness arg.length_pole]),T);
                [mdl.vertices,mdl.faces] =  concatenateTriVert(mdl.vertices,mdl.faces,cv,cubeF);
            end
        end
        mdl.color = mdl.vertices(:,1)*0+255;
    case 'grid'
        D=arg.thickness;
        N = arg.Num;
        
        for x=-N:N
            wh = (x+N+1)*2;
            for y=-N:N
                
                ll = (y+N+1)*2;
                fprintf('L=%f,XY=%f\n',ll,wh);
                T = [x*D y*D bg_distance-ll/2];
                cv = bsxfun(@plus,cubeV*D/2,T);
                [mdl.vertices,mdl.faces] =  concatenateTriVert(mdl.vertices,mdl.faces,cv,cubeF);
            end
        end
        mdl.color = mdl.vertices(:,1)*0+255;
    case 'wlgrid'
        D=30;
       
        N = arg.Num;
        LL = [1/4 1/2 1 2];
        for x=1:N
            wh = x;
            for y=-2:1
                xn = x-N/2-1;
                yn = (y+.5);
                ll = LL(y+3)*wh;
                fprintf('L=%f,XY=%f\n',ll,wh);
                T = [x*D y*D bg_distance-ll/2];
                cv = bsxfun(@plus,cubeV*diag([wh,wh,ll]),T);
                T = [xn*D yn*D bg_distance-ll];
                cv = bsxfun(@plus,(cubeV+.5)*diag([wh,wh,ll]),T);
                [mdl.vertices,mdl.faces] =  concatenateTriVert(mdl.vertices,mdl.faces,cv,cubeF);
            end
        end
        mdl.color = mdl.vertices(:,1)*0+255;
    case 'CubesChart'
        bg_margin = 60;
        bg_width = 5;
        
        D=40; %spacing between each middle of pole - [mm]
       
        %sizes of each squere pole: 1'st elememt is the width and 2'nd is
        %hight [mm]
        sz = cell(5,9);
        last_row_hight = [1 1 2 2 2 3 3 4 4];
        for i=1:9
            sz(1,i) = {[2*i+8,2*i+8]};
            sz(2,i) = {[2*i+8,i+4]};
            sz(3,i) = {[i,2*i]};
            sz(4,i) = {[i,i]};
            sz(5,i) = {[i,last_row_hight(i)]};
        end
        
        for x=1:9
            for y=1:5
                xn = x-1-9/2;
                yn = y-1-5/2;
                fprintf('L=%f,XY=%f\n',sz{6-y,x}(2),sz{6-y,x}(1));
                %placement relative to the middle
                placement = [xn*D-(sz{6-y,x}(1)/2) yn*D-(sz{6-y,x}(1)/2) bg_distance-sz{6-y,x}(2)];
                %vartices of the cube
                cv = bsxfun(@plus,(cubeV+.5)*diag([sz{6-y,x}(1),sz{6-y,x}(1),sz{6-y,x}(2)]),placement);
                
                [mdl.vertices,mdl.faces] =  concatenateTriVert(mdl.vertices,mdl.faces,cv,cubeF);
            end
        end  
        mdl.color = mdl.vertices(:,1)*0+255;
        
    otherwise
        error('bad type');
end


[minx,maxx] = minmax(mdl.vertices(:,1));
[miny,maxy] = minmax(mdl.vertices(:,2));
[minz,maxz] = minmax(mdl.vertices(:,3));
[mdl.vertices,mdl.faces] =  concatenateTriVert(mdl.vertices,mdl.faces,[(cubeV(:,1)+.5)*(maxx-minx+2*bg_margin)+minx-bg_margin (cubeV(:,2)+.5)*(maxy-miny+2*bg_margin)+miny-bg_margin bg_distance+(cubeV(:,3)+.5)*bg_width],cubeF);
mdl.color = [mdl.color;ones(size(cubeV,1),1)*255];
%whith color


fprintf('bounding box size: %dx%dx%d\n',round(maxy-miny),round(maxx-minx),round(maxz-minz));





if( ~isempty(arg.axes_handle) && ishandle(arg.axes_handle) )
    axes(arg.axes_handle);
else
    ff = figure;  
    %setting the data cursor lebels
    dcm_obj = datacursormode(ff);
    set(dcm_obj,'UpdateFcn',@data_cursor_fnc)
end








%add fiducials
if( arg.fiducial>=0 )

    
    rin = bg_margin/6;
    rout = bg_margin/3;
   
    angle = pi/360:pi/360:2*pi;
    x_in = rin*cos(angle);
    x_out = rout*cos(angle);
    y_in = rin*sin(angle);
    y_out = rout*sin(angle);
    
    f_hole = delaunay(x_in,y_in);
    v_hole = [x_in;y_in;y_in*0+bg_distance-0.002]'; 
    f_fidu = delaunay(x_out,y_out);
    v_fidu = [x_out;y_out;y_out*0+bg_distance-0.001]';
    %highet is different between the BG, fiducial and hole:
    %because it's a coloring problem when on the same plane
    
    
    
    %fiducial color
    c = round(arg.fiducial*2.55);
    
    [v_fidu,f_fidu,c_fidu] =  concatenateTriVert(v_fidu,f_fidu,v_fidu(:,1)*0+c,v_hole,f_hole,v_hole(:,1)*0+mdl.color(1));


    %draw the 4 fiducials:
    v_fidu_final = [];
    f_fidu_final = [];
    c_fidu_final = [];
    for i=1:4
        v_fidu_tmp = v_fidu;
        if (i == 1 || i == 3)
            v_fidu_tmp(:,1) = v_fidu(:,1)+abs(maxx)+bg_margin/3;
        else
            v_fidu_tmp(:,1) = v_fidu(:,1)-abs(minx)-bg_margin/3; 
        end
        
        if (i == 2 || i == 3)
            v_fidu_tmp(:,2) = v_fidu(:,2)+abs(maxy)+bg_margin/3;
        else
            v_fidu_tmp(:,2) = v_fidu(:,2)-abs(miny)-bg_margin/3;
        end
        
        [v_fidu_final, f_fidu_final,c_fidu_final] = concatenateTriVert(v_fidu_final, f_fidu_final,c_fidu_final, v_fidu_tmp, f_fidu,c_fidu);
    end


    %add to model
    [mdl.vertices,mdl.faces,mdl.color] =  concatenateTriVert(mdl.vertices,mdl.faces,mdl.color,v_fidu_final, f_fidu_final,c_fidu_final);
  
end

target = trisurf(mdl.faces,mdl.vertices(:,1),mdl.vertices(:,3),mdl.vertices(:,2),mdl.color);axis equal;

%lightning & coloring
caxis([0 255]);
colormap gray
axis equal;
% camlight left
camlight head
shading interp
lighting flat
xlabel('x');
ylabel('z');
zlabel('y');

material(target,'dull');

%add camera
if( strcmp(arg.camera,'on') )
    hold on;
    plotCam(rotation_matrix(pi/2,0,0),zeros(3,1),100,[1 0 0],[2 0 0;0 2 0; 0 0 1]);
    hold off;
end

%add normals
if( strcmp(arg.vectors,'on') )
    hold on;
    [n,v]=calcNorms(mdl.vertices,mdl.faces);
    quiver3(v(:,1),v(:,3),v(:,2),n(:,1),n(:,3),n(:,2),'color','r');
    hold off;
end



%write .stl to file
if(   strcmp('char',class(arg.outfn))   )  
    tmp = mdl.vertices(:,2);
    mdl.vertices(:,2) = mdl.vertices(:,3);
    mdl.vertices(:,3) = tmp;
    stlwrite(arg.outfn,mdl,'facecolor',[mdl.color,mdl.color,mdl.color]);
    fprintf('Wrote %s\n',arg.outfn);
end

end





function [V,Tri,Ue_i,Ue]=particleSampleSphere(varargin)
% Create an approximately uniform triangular tessellation of the unit
% sphere by minimizing generalized electrostatic potential energy
% (aka Reisz s-energy) of the system of charged particles. Effectively,
% this function produces a locally optimal solution to the problem that
% involves finding a minimum Reisz s-energy configuration of N equal
% charges confined to the surface of the unit sphere (s=1 corresponds to
% the problem originally posed by J. J. Thomson).
%
% SYNTAX:
% [V,Tri,Ue_i,Ue]=ParticleSampleSphere(option_i,value_i,option_j,value_j,...)
%
% OPTIONS:
%   - 'N'    : desired number of particles. Corresponding value of N must
%              be a positive interger greater than 9 and less than 1001.
%              N=200 particles is the default setting.
%   - 'Vo'   : particle positions used to initialize the search.
%              Corresponding value of Vo must be a N-by-3 array, where n is
%              the number of particles. N=10 is the lowest permissible
%              number of particles. Initializations consisting of more than
%              1E3 particles are admissible but may lead to unreasonably
%              long optimization times.
%   - 's'    : Reisz s-energy parameter used to control the strength of
%              particle interactions. Corresponding value of s must be
%              a real number greater than zero. s=1 is the default setting.
%   - 'Etol' : covergence tolerance. Coresponding value of Etol must be
%              a real, positive number. Etol=1E-5 is the default setting.
%   - 'Nitr' : Maximum number of iterations. Corresponding value of Nitr
%              must be a non-negative interger. Nitr=1E3 is the default
%              setting.
%
% OUTPUT:
%   - V     : N-by-3 array of vertex positions.
%   - Tri   : M-by-3 list of face-vertex connectivities.
%   - Ue_i  : N-by-1 array of particle energies.
%   - Ue    : K-by-1 array of energy scores, where K-1 was the total number
%             of iterations. Ue(1) corresponds to the energy of the initial
%             configuration.
%
% EXAMPLE:
% -------------------------------------------------------------------------
% % Uniformly distribute 100 particles across the surface of the unit sphere
%
%  [V,Tri,~,Ue]=ParticleSampleSphere('N',100);
%  figure, plot(0:numel(Ue)-1,Ue,'.-')
%  set(get(gca,'Title'),'String','Optimization Progress','FontSize',20)
%  xlabel('Iteration #','FontSize',15)
%  ylabel('Reisz s-enrgy','FontSize',15)
%  TR=TriRep(Tri,V);
%  figure, h=trimesh(TR); set(h,'EdgeColor','b'), axis equal
% -------------------------------------------------------------------------
%
% AUTHOR: Anton Semechko (a.semechko@gmail.com)
% DATE: June.2012
%

try
    if(gpuDeviceCount==1);
        useGPU = true;
    else
        useGPU = false;
    end
catch
    useGPU = false;
end
% Check the inputs
[V,s,Etol,Nitr]=VerifyInputArgs(varargin);
N=size(V,1);    % number of particles
clear varargin

% Compute geodesic distances between the points
DOT=V*V';       % dot product
DOT(DOT<-1)=-1; DOT(DOT>1)=1;
GD=acos(DOT);   % geodesic distance

% Evaluate the energy functional
GD(1:(N+1):end)=Inf; % set diagonal entries of GD to Inf
Ue_ij=1./((GD.^s)+eps);
Ue_i=sum(Ue_ij,2);
Ue=sum(Ue_i);

% Iteratively optimize the position of the particles along the negative
% gradient of the energy functional using an adaptive Gauss-Seidel
% update scheme -----------------------------------------------------------


t0=clock;
i=0;

a=ones(N,1);    % step sizes used during position updates
a_min=1E-14;    % minimum step size
a_max=0.1;      % maximum step size
dE=Inf;


while i<Nitr && dE>Etol
    
    i=i+1;
    
    % Sort the particles according to their energy contribution
    [~,idx_sort]=sort(Ue_i,'descend');
    
    % Update the position of individual particles
    for k=1:N
        
        j=idx_sort(k);
        
        idx_j=true(N,1); % particle indices, except the current one
        idx_j(j)=false;
        
        DOTj=DOT(idx_j,j);
        GDj=GD(idx_j,j);
        
        % Compute the gradient for the j-th particle
        dVj=bsxfun(@times,s./(sqrt(1-DOTj.^2)+eps),V(idx_j,:));
        dVj=bsxfun(@rdivide,dVj,(GDj.^(s+1))+eps);
        if i<5 % remove contributions from particles which are too close
            idx_fail=sum(dVj.^2,2)>(1E4)^2;
            dVj(idx_fail,:)=[];
            if isempty(dVj) % perturb initial positions
                V=V+randn(size(V))/1E5;
                V_L2=sqrt(sum(V.^2,2));
                V=bsxfun(@rdivide,V,V_L2);
                DOT=V*V';
                GD=acos(DOT);
                break
            end
        end
        dVj=sum(dVj,1);
        
        % Only retain the tangential component of the gradient
        dVj_n=(dVj*V(j,:)')*V(j,:);
        dVj_t=dVj-dVj_n;
        
        % Adaptively update position of the j-th particle
        m=0;
        Uj_old=sum(Ue_ij(j,:));
        while true
            
            % Update the position
            Vj_new=V(j,:)-a(j)*dVj_t;
            
            % Constrain the point to surface of the sphere
            Vj_new=Vj_new/norm(Vj_new);
            
            % Recompute the dot products and the geodesics
            DOTj=sum(bsxfun(@times,V,Vj_new),2);
            DOTj(DOTj<-1)=-1; DOTj(DOTj>1)=1;
            GDj=acos(DOTj);
            GDj(j)=Inf;
            
            Ue_ij_j=1./((GDj.^s)+eps);
            
            % Check if the system potential decreased
            if sum(Ue_ij_j)<=Uj_old
                
                V(j,:)=Vj_new;
                
                DOT(j,:)=DOTj';
                DOT(:,j)=DOTj;
                
                GD(j,:)=GDj';
                GD(:,j)=GDj;
                
                Ue_ij(j,:)=Ue_ij_j';
                Ue_ij(:,j)=Ue_ij_j;
                
                if m==1, a(j)=a(j)*2.5; end
                if a(j)>a_max, a(j)=a_max; end
                
                break
                
            else
                
                if a(j)>a_min
                    a(j)=a(j)/2.5;
                    if a(j)<a_min, a(j)=a_min; end
                else
                    break
                end
                
            end
            
        end
        
    end
    
    % Evaluate the total energy of the system
    Ue_i=sum(Ue_ij,2);
    Ue(i+1)=sum(Ue_i);
    
    % Progress update
    
    % Change in energy
    if i>=10, dE=(Ue(i-2)-Ue(i+1))/10; end
    
    % Reset the step sizes
    if mod(i,20)==0, a=a_max*ones(N,1); end
    
end
clear DOT GD Ue_ij
if Nitr==0, fprintf('%u\t        %.3f\t\n',i,Ue(1)); end
if mod(i,50)~=0, fprintf('%u\t        %.3f\t\n',i,Ue(end)); end

try
    Tri=fliplr(convhulln(V));
catch err
    msg=sprintf('Unable to triangulate the points. %s',err.message);
    disp(msg)
    Tri=[];
end

end
%==========================================================================
function [V,s,Etol,Nitr]=VerifyInputArgs(VarsIn)


% Make sure all supplied input argumets have valid format


% Default settings
V=RandSampleSphere(200,'stratified');
s=1; Etol=1E-5; Nitr=1E3;
if isempty(VarsIn), return; end

% First check that there is an even number of inputs
Narg=numel(VarsIn);
if mod(Narg,2)~=0
    error('Incorrect number of input arguments')
end

% Get the properties
FNo={'N','Vo','s','Etol','Nitr'};
flag=false(1,5); exit_flag=false;
for i=1:Narg/2
    
    % Make sure the input is a string
    str=VarsIn{2*(i-1)+1};
    if ~ischar(str)
        error('Input argument #%u is not valid',2*(i-1)+1)
    end
    
    % Get the value
    Val=VarsIn{2*i};
    
    % Match the string against the list of avaliable options
    chk=strcmpi(str,FNo);
    id=find(chk,1);
    if isempty(id), id=0; end
    
    switch id
        case 1 % number of particles
            
            % Check if 'initialization' option has also been specified
            if flag(2)
                error('Ambigious combination of options. Specify option ''%s'' or option ''%s'', but not both.',FNo{2},FNo{1})
            end
            
            % Check the format
            if sum(Val(:)<10)>0 || sum(Val(:)>1E3)>0 || ~isreal(Val) || ~isnumeric(Val) || numel(Val)~=1
                error('Incorrect entry for the ''%s'' option. N must be a positive interger greater than 9 and less than 1001.',FNo{1})
            end
            V=RandSampleSphere(round(Val),'stratified'); %#ok<*NASGU>
            
        case 2 % initialization
            
            % Check if 'number' option has also been specified
            if flag(1)
                error('Ambigious combination of options. Specify option ''%s'' or option ''%s'', but not both.',FNo{1},FNo{2})
            end
            
            % Check the format
            if ~isreal(Val) || ~isnumeric(Val) || size(Val,2)~=3 || size(Val,1)<10
                error('Incorrect entry for the ''%s'' option. Vo must be a N-by-3 array, where N is the number of particles. N=10 is the lowest number allowed.',FNo{2})
            end
            
            % Make sure the particles are constrained to the surface of the unit sphere
            V=Val;
            V_L2=sqrt(sum(V.^2,2));
            V=bsxfun(@rdivide,V,V_L2);
            clear Val V_L2
            
            % Check if there are more than 1E3 particles
            if size(V,1)>1E3
                
                % Construct a 'yes'/'no' questdlg
                choice = questdlg('Default particle limit exceeded. Would you like to continue?', ...
                    'Particle Limit Exceeded','   YES   ','   NO   ','   NO   ');
                
                % Handle response
                if strcmpi(choice,'   NO   '), exit_flag=true; end
                
            end
            
        case 3 % s parameter
            
            % Check the format
            if Val<0 || ~isreal(Val) || ~isnumeric(Val) || numel(Val)~=1
                error('Incorrect entry for the ''%s'' option. s must be a positive real number.',FNo{3})
            end
            s=Val;
            
        case 4 % energy tolerance parameter
            
            % Check the format
            if Val<0 || ~isreal(Val) || ~isnumeric(Val) || numel(Val)~=1
                error('Incorrect entry for the ''%s'' option. Etol must be a positive real number.',FNo{4})
            end
            Etol=Val;
            
        case 5 % maximum number of iterations
            
            % Check the format
            if Val<0 || ~isreal(Val) || ~isnumeric(Val) || numel(Val)~=1
                error('Incorrect entry for the ''%s'' option. Nitr must be a non-negative integer.',FNo{5})
            end
            Nitr=Val;
            
        otherwise
            error('''%s'' is not a valid option',str)
    end
    flag(id)=true;
    
end

if exit_flag, Nitr=0; end %#ok<*UNRCH>

end
function X=RandSampleSphere(N,spl)
% Generate a random or stratified sampling a unit sphere.
%
% INPUT ARGUMENTS:
%   - N   : desired number of point samples. N=200 is default.
%   - spl : can be 'stratified' or 'random'. The former setting is the
%           default.
%
% OUTPUT:
%   - X  : N-by-3 array of sample point coordinates.
%
% AUTHOR: Anton Semechko (a.semechko@gmail.com)
% DATE: June.2012
%

if nargin<1 || isempty(N), N=200; end
if nargin<2 || isempty(spl), spl='uniform'; end

switch spl
    
    case 'uniform'
        
        % Generate uniform (although random) sampling of the sphere
        z=2*rand(N,1)-1;
        t=2*pi*rand(N,1);
        r=sqrt(1-z.^2);
        x=r.*cos(t);
        y=r.*sin(t);
        
    case 'stratified'
        
        % Uniformly sample the unfolded right cylinder
        lon=2*pi*rand(N,1);
        z=2*rand(N,1)-1;
        
        % Convert z to latitude
        lat=acos(z);
        
        % Convert spherical to rectangular co-ords
        x=cos(lon).*sin(lat);
        y=sin(lon).*sin(lat);
        
    otherwise
        
        error('Invalid option')
        
end



X=[x,y,z];
end


function txt = data_cursor_fnc(empty,event_obj)
% Customizes text of data tips

pos = get(event_obj,'Position');
txt = {['X: ',num2str(pos(1))],...
    ['Y: ',num2str(pos(3))],...
    ['Z: ',num2str(pos(2))]};

end