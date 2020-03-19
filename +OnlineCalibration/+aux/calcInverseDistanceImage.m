
function [D,dbg] = calcInverseDistanceImage(E,params)
    % todo - make the scan diagonal 
    
    tic;
    D = E;
    D = scanOneDir(D,params);
    D = rot90(scanOneDir(rot90(D,2),params),2);
    D = params.alpha*E + (1-params.alpha)*D;
    
    time = toc;
%     fprintf('calcInverseDistanceImage took %3.2f seconds\n',time);
    
    
    Dred = uint8(zeros(size(D,1),size(D,2),3));
    Dred(:,:,1) = uint8(D);
%     Dred(repmat(D,1,1,3) < 10 ) = repmat(yuy2Med(D<10),1,1,3);
    dbg.Dred = Dred;
end
function D = scanOneDir(D,params)
    for i = 1:size(D,1)
        for j = 1:size(D,2)
            if i == 1 && j == 1 
                D(i,j) = max(D(i,j));
            elseif i == 1 
                D(i,j) = max([D(i,j),D(i,j-1)*params.gamma]);
            elseif j == 1
                D(i,j) = max([D(i,j),D(i-1,j)*params.gamma]);
            else
                D(i,j) = max([D(i,j),D(i-1,j)*params.gamma,D(i,j-1)*params.gamma]);
            end
                
        end
    end
    
end

