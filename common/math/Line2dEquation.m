classdef Line2dEquation
%---------2D line equation class----------%
% created by Ohad Menashe 2010

    properties (Access = private)
        u
        c
    end
    
    
    methods(Static, Access = private)
        function [c,n] = priv_clsq(A)
            [m,p] = size(A);
            if p < 3, error ('not enough unknowns'); end;
            if m < 2, error ('not enough equations'); end;
            m = min (m, p);
            [~,R] =(qr (A));
            [~,~,V] = svd(R(p-1:m,p-1:p));
            n = V(:,2);
            c = -R(1:p-2,1:p-2)\R(1:p-2,p-1:p)*n;
        end
        
        function [ou,oc] = priv_LSQlineFit(x,y)
            mth = 0;
            switch(mth)
                case 0
                    mx = mean(x);
                    my = mean(y);
                    
                    x = x-mx;
                    y = y-my;
                    A = [ones(size(x)) x y];

                    [cc , uu] = Line2dEquation.priv_clsq(A);
                    
                    
                    err = abs(A*[cc ; uu]);
                    thr = prctile(err,75);
                    if(nnz(err<thr)>3)
                    [cc , uu] = Line2dEquation.priv_clsq(A(err<thr,:));
                    end
                    ou = uu(1)+1j*uu(2);
                    oc =cc-uu(1)*mx-uu(2)*my;
                case 1
                    mx = mean(x);
                    my = mean(y);
                    
                    x = x-mx;
                    y = y-my;
                    A = [x y ones(size(x))];
                    [v,~]=eig(A'*A);
                    v = v(:,1)/norm(v(1:2,1));
                    uu = v(1:2);
                    cc = v(3);
                    ou = uu(1)+1j*uu(2);
                    oc =cc-uu(1)*mx-uu(2)*my;
                case 2
                    zs = x+1j*y;
                    zm = mean(zs);
                    z2sum = sum(zs.*zs);
                    z2nrm = norm(z2sum);
                    if(z2nrm ~= 0)
                        z2sum = z2sum/ z2nrm;
                    end
                    p = conj(z2sum)*conj(z2sum);
                    if(real(z2sum)>0)
                        tu = 1;
                    else
                        tu = 1j;
                    end
                    a = sqrt(sqrt(p))*tu;
                    p = zm;
                    q = zm - conj(a);
                    x1 = real(p);
                    y1 = imag(p);
                    x2 = real(q);
                    y2 = imag(q);
                    ou = (y1-y2) + 1j*(x2-x1);
                    oc = (x1-x2)*y1 + (y2-y1)*x1;
                    
            end
        end
    end
    methods (Access = public)
        function obj = Line2dEquation(varargin)
            switch(nargin)
                case 1
                    obj.u = varargin{1}(1)+1j*varargin{1}(2);
                     obj.c =varargin{1}(3);
                     n = norm(obj.u);
                    obj.u = obj.u/n;
                    obj.c = obj.c/n;
                case 2
                    %p,q
                    x = varargin{1};
                    y = varargin{2};
                    x = x(:);y=y(:);
                    if(length(x)==2)
                        xyo=cross([x(1) y(1) 1],[x(2) y(2) 1]);
                        xyo=xyo/norm(xyo(1:2));
                        obj.u = xyo(1)+1j*xyo(2);
                        obj.c = xyo(3);
                    else
                    
                    [obj.u,obj.c] = Line2dEquation.priv_LSQlineFit(x,y);
                    end
                case 3
                    %a,b,c
                    obj.u = varargin{1}+1j*varargin{2};
                    obj.c = varargin{3};
                    n = norm(obj.u);
                    obj.u = obj.u/n;
                    obj.c = obj.c/n;
            end
        end
        
        
        function v=dist(obj,x,y)
            z = x+1j*y;
            proj = z*conj(obj.u);
            v=real(proj) +obj.c;
        end
        
        function v=y(obj,x)
            if(obj.B()==0)
                v = nan;
            else
                v=-(obj.A()*x+obj.C())/obj.B();
            end
        end
        
        function v=x(obj,y)
            if(obj.A()==0)
                v = nan;
            else
                v=-(obj.B()*y+obj.C())/obj.A();
            end
        end
        
        
        function v=A(obj)
            v=real(obj.u);
        end
        function v=B(obj)
            v=imag(obj.u);
        end
        function v=C(obj)
            v=obj.c;
        end
        
        function v=uu(obj)
            v=(obj.u);
            v = [real(v);imag(v)];
        end
        
        function v=t(obj,x,y)
            z = x+1j*y;
            v=imag(z*conj(obj.u));
        end
        
        function [x,y]=xy(obj,r)
            r = r(:);
            v=bsxfun(@times,obj.u,(-obj.c +1j* r ));
            x = real(v);
            y = imag(v);
        end
        
       
        function disp(obj)
            fprintf('%g*x%+g*y%+g=0\n',obj.A(),obj.B(),obj.C());
        end
        
        function a=ang(obj)
            a = pi-atan2(obj.A(),obj.B());
        end
        
        function a=plot(obj,varargin)
            
            abc = [obj.A() obj.B() obj.C()];
            a=plotLine(abc,varargin{1:end});
        end
        
        function [x,y]=and(obj0,obj1)
    
            H = [obj0.A() obj0.B();obj1.A() obj1.B()];
            b = -[obj0.C();obj1.C()];
            z = H\b;
            x = z(1);
            y = z(2);
            
        end
        
        
    end
end