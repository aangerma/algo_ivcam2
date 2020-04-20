function [D,dbg] = calcInverseDistanceImage2(E,params)
    % todo - make the scan diagonal 
    
    tic;
    D = E;
    [x,y] = meshgrid(1:size(D,2),1:size(D,1));
    Porigin = cat(3,y,x);
    Dorigin = D;
    [D,Dorigin,Porigin] = scanOneDir(D,Dorigin,Porigin,params);
    Drot = rot90(D,2);
    Doriginrot = rot90(Dorigin,2);
    Poriginrot = rot90(Porigin,2); 
    Poriginrot(:,:,1) = size(D,1) + 1 - Poriginrot(:,:,1);
    Poriginrot(:,:,2) = size(D,2) + 1 - Poriginrot(:,:,2);
    [D,~,~] = scanOneDir(Drot,Doriginrot,Poriginrot,params);
    D = rot90(D,2);
    D = params.alpha*E + (1-params.alpha)*D;
    
    Dred = uint8(zeros(size(D,1),size(D,2),3));
    Dred(:,:,1) = uint8(D);
%     Dred(repmat(D,1,1,3) < 10 ) = repmat(yuy2Med(D<10),1,1,3);
    dbg.Dred = Dred;
end
function [D,Dorigin,Porigin] = scanOneDir(D,Dorigin,Porigin,params)
    
    for i = 1:size(D,1)
        for j = 1:size(D,2)
            p = cat(3,i,j);
            if i == 1 && j == 1 
                D(i,j) = max(D(i,j)); 
                Dorigin(i,j) = D(i,j);
                Porigin(i,j,:) = p;
            elseif i == 1
                pOpts = [[i;j],[i;j-1]];
                [D(i,j),ind] = max([D(i,j),Dorigin(i,j-1)*params.gamma.^sqrt(sum((p-Porigin(i,j-1,:)).^2))]);
                Dorigin(i,j) = Dorigin(pOpts(1,ind),pOpts(2,ind));
                Porigin(i,j,:) = Porigin(pOpts(1,ind),pOpts(2,ind),:);
            elseif j == 1
                pOpts = [[i;j],[i-1;j]];
                [D(i,j),ind] = max([D(i,j),Dorigin(i-1,j)*params.gamma.^sqrt(sum((p-Porigin(i-1,j,:)).^2))]);
                Dorigin(i,j) = Dorigin(pOpts(1,ind),pOpts(2,ind));
                Porigin(i,j,:) = Porigin(pOpts(1,ind),pOpts(2,ind),:);
            else
                pOpts = [[i;j],[i-1;j],[i;j-1]];
                [D(i,j),ind] = max([D(i,j),Dorigin(i-1,j)*params.gamma.^sqrt(sum((p-Porigin(i-1,j,:)).^2)),...
                                           Dorigin(i,j-1)*params.gamma.^sqrt(sum((p-Porigin(i,j-1,:)).^2))]);
                Dorigin(i,j) = Dorigin(pOpts(1,ind),pOpts(2,ind));
                Porigin(i,j,:) = Porigin(pOpts(1,ind),pOpts(2,ind),:);
            end
                
        end
    end
    
end

