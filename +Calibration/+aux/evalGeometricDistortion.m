function [e,e_dist,ptsOut]=evalGeometricDistortion(p,d,verbose)
%%
tileSizeMM = 30;
h=size(p,1);
w=size(p,2);
p=p(:,:,1:3);
[oy,ox]=ndgrid(linspace(-1,1,h)*(h-1)*tileSizeMM/2,linspace(-1,1,w)*(w-1)*tileSizeMM/2);
ptsOpt = [ox(:) oy(:) zeros(w*h,1)]';

%set measurments as Nx3
ptsMes =reshape(v(:,:,1:3),[],3)';

[~,fitP] = rigidFit(xyzmes,ptsOpt);
diff = sqrt(sum((xyzmes-fitP).^2));

% Remove outlier points when we are close to the right solution.
if sum(diff<tileSizeMM/2)>=(w*h-h)
    valid = logical(valid .* (diff<tileSizeMM/2));
end
%remove mean
valid = logical(valid.*d.valid'); % Add the validity map from undistort function.
c = mean(ptsMes,2);
ptsMes=ptsMes-c;

%rotate optimal to measurment
[e_dist,fitP] = rigidFit(xyzmes,ptsOpt);
rotmat=u*vt';
ptsoptR=rotmat*ptsOpt;

%calc error
ve = ptsoptR-ptsMes;
d = @(e) (sqrt(sum(e.^2)));
e=sqrt(mean(d(ve(:))));
ve=permute(reshape(ve,3,h,w),[2 3 1]);
if(exist('verbose','var') && verbose)
    %%
    figure(190789);clf
    subplot(1,3,1:2);
    plot3(ptsMes(1,:),ptsMes(2,:),ptsMes(3,:),'ro',ptsoptR(1,:),ptsoptR(2,:),ptsoptR(3,:),'g.');
    plot3(xyzmes(1,valid),xyzmes(2,valid),xyzmes(3,valid),'ro',fitP(1,:),fitP(2,:),fitP(3,:),'g.',xyzmes(1,logical(1-valid)),xyzmes(2,logical(1-valid)),xyzmes(3,logical(1-valid)),'bo');
    titlestr = sprintf('Checkerboard Points in 3D.\n eGeom = %.2f. Invalid#=%d',e,sum(1-valid));
    xlabel('x'),ylabel('y'),zlabel('z'),title('Checkerboard Points in 3D')
        legend({'Measurements' 'Reference','Invalids'})
    else
    
    quiver3(v(:,:,1),v(:,:,2),v(:,:,3),ve(:,:,1),ve(:,:,2),ve(:,:,3),0)
    hold off;
    legend({'Measurements' 'Reference','offset'},'location','best');
    grid on;
    subplot(1,3,3);
    imagesc(sqrt(sum(ve.^2,3)));axis image;axis off;colorbar('SouthOutside')
    %     axis equal
    drawnow;
end

return
