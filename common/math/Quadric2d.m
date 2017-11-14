classdef Quadric2d
    properties (Access = private)
        v
        fitErr
    end
    methods
        
        function obj = Quadric2d(x_,y_,w)
            
            if(length(x_)<5 )
                obj.v = nan(5,1);
                return;
            end
            
            if(~exist('w','var'))
                w = ones(size(x_));
            end
            x_=x_(:);
            y_=y_(:);
            w=w(:)/sum(w);
            
            mx = min(x_);
            Mx = max(x_);
            
            my = min(y_);
            My=max(y_);
            
            x = (x_-mx)/(Mx-mx)*2-1;
            y = (y_-my)/(My-my)*2-1;
            
            
            %evalueate ax^2+by^2+2*cxy+2*dx+2*ey+f=0
            makeH = @(xi,yi) [xi.^2 yi.^2 2*xi.*yi 2*xi 2*yi ones(size(xi))];
            H = [ 2*x 2*y ones(size(x)) x.^2 y.^2 2*x.*y  ];
            [nn,cc]=clsq(H,3);
            th = [cc;nn];
            err = abs(makeH(x,y)*th);
            
            thr = prctile(err,75);
            indx = err<thr;
            if(nnz(indx)>5)
                H = H(indx,:);
                [nn,cc]=clsq(H,3);
                th = [cc;nn];
            end
            a=th(1);b=th(2);c=th(3);d=th(4);e=th(5);f=th(6);
            %{
             syms a b c d e f x_ y_ mx Mx my My x_ y_
              x = (x_-mx)/(Mx-mx)*2-1;
              y = (y_-my)/(My-my)*2-1;
             
             [cx,cy]=coeffs(a*x^2+b*y^2+2*c*x*y+2*d*x+2*e*y+f,[x_,y_]);
             [cx(1) cx(4) cx(2)/2 cx(3)/2 cx(5)/2 cx(6)]
             
            %}
            obj.v=[ (4*a)/(Mx - mx)^2, (4*b)/(My - my)^2, (4*c)/((Mx - mx)*(My - my)), (2*d)/(Mx - mx) - (2*a*((2*mx)/(Mx - mx) + 1))/(Mx - mx) - (2*c*((2*my)/(My - my) + 1))/(Mx - mx), (2*e)/(My - my) - (2*b*((2*my)/(My - my) + 1))/(My - my) - (2*c*((2*mx)/(Mx - mx) + 1))/(My - my), f + a*((2*mx)/(Mx - mx) + 1)^2 + b*((2*my)/(My - my) + 1)^2 - 2*d*((2*mx)/(Mx - mx) + 1) - 2*e*((2*my)/(My - my) + 1) + 2*c*((2*mx)/(Mx - mx) + 1)*((2*my)/(My - my) + 1)]';
            
            
            if(0)
                %%
                [xg,yg]=meshgrid(linspace(-1,1,100));
                xg = (xg+1)/2*(Mx-mx)+mx;
                yg = (yg+1)/2*(My-my)+my;
                
                zg = reshape(makeH(xg(:),yg(:))*obj.v,size(xg));
                surf(xg,yg,zg);
                hold on
                plot3(x_,y_,x_*0,'b.','markersize',30)
                m=obj.mju();
                plot3(m(1),m(2),m(3),'g.','markersize',30)
                hold off
                %%
                %           [xg,yg]=meshgrid(linspace(-1,1,100));
                %              zg = reshape(makeH(xg(:),yg(:))*th+C,size(xg));
                %              surf(xg,yg,zg);
                %              hold on
                %              plot3(x,y,x*0,'b.','markersize',30)
                %               plot3(0,0,C,'r.','markersize',30)
                %              hold off
            end
            %%
            
            
            q = obj.qmat();
            if(det(q)<0 )
                obj.v = nan(5,1);
            end
            obj.fitErr=sum(err);
        end
        
        function q=qmat(obj)
            q = [obj.v(1) obj.v(3);obj.v(3) obj.v(2)];
        end
        
        
        function m=mju(obj)
            if(length(obj)~=1)
                m = arrayfun(@(i) obj(i).mju(),1:length(obj),'uni',false);
                return;
            end
            q = obj.qmat();
            if(any(isnan(q)))
                m=nan(2,1);
                return;
            end
            m = q^-1*[-obj.v(4);-obj.v(5)];
            m(3) = [m(1).^2 m(2).^2 2*m(1)*m(2) 2*m(1) 2*m(2) 1]*obj.v;
        end
        
        
        function [ang,l1,l2] = angLambda(obj)
            %return l1 angle, l1 length and l2 length.
            %-l2 angle is 90-l1 angle.
            %-l1 is alway bigger than l2
            if(length(obj)~=1)
                [ang,l1,l2] = arrayfun(@(i) obj(i).angLambda(),1:length(obj));
                return;
            end
            q = obj.qmat();
            if(any(isnan(q)))
                ang = nan;
                l1 = nan;
                l2 = nan;
                return;
            end
            %             m = obj.mju();
            %             n = 1-[m(1)^2 m(2)^2 2*m(1)*m(2) 2*m(1) 2*m(2)]*obj.v;
            %             q = q/n;
            
            [vv,ll]=eig(q);
            ang = atan2(vv(2,1),vv(1,1));
            
            ll = 1./sqrt(abs(diag(ll)));
            l1=ll(1);
            l2=ll(2);
            
        end
        
        function z = at(obj,xy)
            x = xy(:,1);
            y = xy(:,2);
            z = obj.v(1)*x.^2+obj.v(2)*y.^2+2*obj.v(3)*x.*y+2*obj.v(4)*x+2*obj.v(5)*y-1;
        end
        
        
        
        function disp(obj)
            obj.display(obj)
        end
        function display(obj)
            if(length(obj)~=1)
                fprintf('%d x Quadric2d',length(obj));
                return;
            end
            m=obj.mju();
            [ang,l1,l2] = obj.angLambda();
            
            fprintf('| x  y || %+5.2e , %+5.2e ||x|    | %+5.2e ||x|    \t\tm =      [%5.2f %5.2f]\n',obj.v(1),2*obj.v(3),2*obj.v(4),m(1),m(2));
            fprintf('        | %9.00s   %9.00s || | +  | %9.00s || | = 1\t\tlambda = [%5.2f %5.2f]\n',' ',' ',' ',l1,l2);
            fprintf('        | %+5.2e , %+5.2e ||y|    | %+5.2e ||y|    \t\tangle =  %5.2fdeg\n',2*obj.v(3),obj.v(2),2*obj.v(5),ang*180/pi);
            %             fprintf('\n-----------------------------------------------------------------\n');
            %             fprintf('%+5.2e  ',[obj.v;1]);
            %             fprintf('\n');
        end
        
        function h = plot(varargin)
            obj=varargin{1};
            if(length(obj)~=1)
                h = arrayfun(@(i) obj(i).plot(varargin{2:end}),1:length(obj));
                return;
            end
            N=100;
            t = linspace(0,2*pi,N)';
            m=obj.mju();m=m(1:2);
            [a,l1,l2] = obj.angLambda();
            
            xy = [cos(t)*l1 sin(t)*l2];
            R = [cos(a) sin(a);-sin(a) cos(a)];
            xy = bsxfun(@plus,xy*R,m');
            h=plot(xy(:,1),xy(:,2),varargin{2:end});
            
            
        end
        
        function v = coefs(obj)
            v=obj.v;
        end
        
        function err=fitError(obj)
            err = obj.fitErr;
        end
    end
end
