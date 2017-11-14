function stlwriteMatrix(fn,x,y,z,varargin)
    %{
c,stlTitle,facetsDirUp
    %}
    
    inp = inputParser;
    isfileorchar = @(x) or(ischar(x),isnumeric(x));
    inp.addRequired('fn', @(x)isfileorchar(x));
    inp.addRequired('x' , @(x)isreal(x));
    inp.addRequired('y' , @(x)isreal(x));
    inp.addRequired('z' , @(x)isreal(x));
    
    inp.addOptional('color',zeros(size(x)));
    inp.addOptional('title','MatlabGenSTL');
    inp.addOptional('facetsDirUp',true);
    inp.addOptional('verbose',false);
    
    inp.parse(fn,x,y,z,varargin{:});
    arg = inp.Results;
    clear('inp');
    
    
    c = arg.color;
    if(size(c,3)==1)
        c=cat(3,c,c,c);
    end
    switch(class(c))
        case 'uint16'
            c = uint8(bitshift(c,-8));
        case 'uint8'
            
        case {'double','single'}
               tblim = prctile_(c(c(:)~=0),[1 99]);
        c = uint8((double(c)-tblim(1))/diff(tblim)*255);
    end

    
    if(~isequal(size(x),size(y),size(z)))
        error('size sould be the same');
    end
    
    [h,w,~]=size(x);
    [gy,gx]=ndgrid(1:h,1:w);
    v = single([x(:) y(:) z(:)]');
    
    cv=[reshape(c(:,:,1),1,[]);reshape(c(:,:,2),1,[]);reshape(c(:,:,3),1,[])];
    indA0=sub2ind([h,w],gy(1:end-1,1:end-1),gx(1:end-1,1:end-1));
    indA1=sub2ind([h,w],gy(2:end,2:end),gx(2:end,2:end));
    indA2=sub2ind([h,w],gy(1:end-1,1:end-1),gx(2:end,2:end));
    indB0=sub2ind([h,w],gy(1:end-1,1:end-1),gx(1:end-1,1:end-1));
    indB1=sub2ind([h,w],gy(2:end,2:end),gx(1:end-1,1:end-1));
    indB2=sub2ind([h,w],gy(2:end,2:end),gx(2:end,2:end));
    if(~arg.facetsDirUp)
        [indA1,indA2]=deal(indA2,indA1);
        [indB1,indB2]=deal(indB2,indB1);
    end
    
    
    f = [indA2(:) indA1(:) indA0(:);indB2(:) indB1(:) indB0(:)];
    
    
    
    fv = reshape(v(:,f'), 3, 3, []);
    fc=reshape(cv(:,f'), 3, 3, []);
    gi = ~squeeze(any(any(isnan(fv) ,1),2));
    fv = fv(:,:,gi);
    fc = fc(:,:,gi);
    fc = squeeze(uint16(mean(fc,2)));
    % Compute their normals
    v1 = squeeze(fv(:,2,:) - fv(:,1,:));
    v2 = squeeze(fv(:,3,:) - fv(:,1,:));
    n = v1([2 3 1],:) .* v2([3 1 2],:) - v2([2 3 1],:) .* v1([3 1 2],:);
    
    n = bsxfun(@times, n, 1 ./ sqrt(sum(n .* n, 1)));
    fv = cat(2, reshape(n, 3, 1, []), fv);
    if isnumeric(fn)
        fid = fn; % when fn is file identifier!
    else
        fid = fopen(fn,'wb+');
    end
    
    
    fprintf(fid, '%-80s', arg.title);             % Title
    fwrite(fid, size(fv, 3), 'uint32');           % Number of facets
    % Write DATA
    % Add one uint16(0) to the end of each facet using a typecasting trick
    fv = reshape(typecast(fv(:), 'uint16'), 12*2, []);
    % Set the last bit to 0 (default) or supplied RGB
    
    clr = zeros(size(fc,2),1,'uint16');
    if(any(fc(:)~=0))
        %convert color data to 5 bit
        fc = bitshift(fc,-3);
        
        %Red color (10:14), green color (5:9), blue color (0:4)
        clr=fc(3,:)+bitshift(fc(2,:),5)+bitshift(fc(1,:),10)+bitshift(1,15);
    end
    
    fv(end+1,:) = clr;
    fwrite(fid, fv, 'uint16');
    
    if ~isnumeric(fn)
        fclose(fid); % if fn is file identifier, let the caller fclose it!
    end
    
    if(arg.verbose)
        a = findobj(0,'userdata','STLwriteMatrixAxes');
        if(isempty(a))
            h=figure('name','STLwriteMatrix','NumberTitle','off');
            a = axes('parent',h,'userdata','STLwriteMatrixAxes');
        else
            h=findobj(a,'type','surface');
            delete(h);
        end
        
        surface(double(x),double(y),double(z),double(c)/255,'parent',a,'EdgeColor','none');
        
        axis equal;
        grid on
        xlabel('x');
        ylabel('y');
        zlabel('z');
        set(a,'zdir','reverse');
    end
end