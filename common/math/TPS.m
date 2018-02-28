%written by Ohad Menashe MAR 2013
%==============================
%K-dimnetional Thin plate spline object
%usage:
%   construction:
%        t=TPS_kd(source_points,dest_points)
%           -source_points - Nxdim source points
%           -dest_points - Nxdim destination points
%   apply:
%       t.at(pts)
%           -pts - Mxdim points to transform
%       t.tfwd() - forward transformation (src->dst)
%       t.tinv() - inverse transformation (dst->src)
%
% example:
%         img = imread('kids.tif');
%         src = [123 103;156 93;288 179;260 181;146 133];
%         dst = [110 70;169 57;307 150;225 152;142 203];
%         t=TPS(src,dst)
%         img2=imtransform(img,t.tinv(),'xdata',[1 size(img,2)],'ydata',[1 size(img,1)]);
%         imshowpair(img,img2);
%         hold on
%         quiver(src(:,1),src(:,2),dst(:,1)-src(:,1),dst(:,2)-src(:,2),0);
%         hold off

classdef TPS
    properties (Access = private)
        mat
        src
        dst
        verbose
    end
    properties (Constant, Access = private)
        N_MAX_POINTS = 200000; %nominal matrix size
    end
    methods (Static, Access = private)
        function d = Ufunc(v)
            
            nrm = max(sum(v.^2,2),1e-320);
            
            switch(size(v,2))
                case 1,d = nrm.*sqrt(nrm);return; %R^3
                case 2,d = nrm.*log(nrm);return;
                case 3,d = sqrt(nrm);return; %R
                otherwise, d = nrm.^(1-size(v,2)/2);
            end
        end
        
    end
    
    
    methods
        
        
        
        function obj = TPS(src, dst,verbose)
            assert(all(size(src,1)==size(dst,1)));
            if(~exist('verbose','var'))
                verbose=false;
            end
            npnts = size(src,1);
            
            dim = size(src,2);
            dimOut = size(dst,2);
            src = double(src);
            dst = double(dst);
            
            K = zeros(npnts, npnts);
            if(obj.verbose)
                fprintf('[%5.1f%%]',0);
            end
            for rr = 1:npnts
                for cc = 1:npnts
                    K(rr,cc) = obj.Ufunc(src(rr,:)-src(cc,:));
                    K(cc,rr) = K(rr,cc);
                end;
                if(obj.verbose)
                    fprintf('\b\b\b\b\b\b\b\b[%5.1f%%]',rr/npnts*100);
                end
            end;
            if(obj.verbose)
                fprintf('\b\b\b\b\b\b\b\b');
            end
            P = [ones(npnts,1), src];
            
            L = [ [K, P];[P', zeros(dim+1,dim+1)] ];
            obj.mat = pinv(L) * [dst; zeros(dim+1,dimOut)];
            obj.src = src;
            obj.dst = dst;
            obj.verbose=verbose;
        end
        
        
        
        function z = at(obj,ptKd,varargin)
            assert(size(ptKd,2) ==size(obj.src,2),'Input points dim is different than TPS dim');
            
            
            if(size(ptKd,1)<=obj.N_MAX_POINTS)
                K = zeros(size(obj.src,1),size(ptKd,1));
                for i=1:size(ptKd,1)
                    K(:,i)=obj.Ufunc((repmat(ptKd(i,:),size(obj.src,1),1)-obj.src));
                end
                P = [ones(size(ptKd,1),1)  ptKd];
                L = [K'  P];
                z = L * obj.mat;
            else
                z = zeros(size(ptKd,1),size(obj.dst,2));
                if(obj.verbose)
                    fprintf('[%5.1f%%]',0);
                end
                for i=1:obj.N_MAX_POINTS:size(ptKd,1)
                    if(obj.verbose)
                        fprintf('\b\b\b\b\b\b\b\b[%5.1f%%]',i/size(ptKd,1)*100);
                    end
                    indx = i:min(size(ptKd,1),i+obj.N_MAX_POINTS-1);
                    z(indx,:) = obj.at(ptKd(indx,:));
                    
                end
                if(obj.verbose)
                    fprintf('\b\b\b\b\b\b\b\b');
                end
            end
        end
        
        function disp(obj)
            fprintf('TPS dim: %d\nNpoints: %d\n',size(obj.src,2),size(obj.src,1));
        end
        
        
        function t=tfwd(obj)
            dim = size(obj.src,2);
            t = maketform('custom',dim,dim,@obj.at,[],[]);
        end
        
        function t=tinv(obj)
            dim = obj.dim();
            tpsinv = obj.inv();
            t = maketform('custom',dim,dim,[],@tpsinv.at,[]);
        end
        
        function d=dim(obj)
            d = size(obj.src,2);
        end
        
        function s = srcPts(obj)
            s = obj.src;
        end
        function s = dstPts(obj)
            s = obj.at(obj.src);
        end
        
        function tpsinv=inv(obj)
            tpsinv = TPS(obj.dst,obj.src);
        end
        
        function tpsC=mtimes(tpsA,tpsB)
            srcA = tpsA.srcPts();
            srcB = tpsA.inv().at(tpsB.src);
            
            dstA = tpsB.at(tpsA.at(tpsA.src));
            dstB = tpsB.dstPts();
            
            tpsC = TPS_Kd([srcA;srcB],[dstA;dstB]);
            
        end
        
        
        
    end
end