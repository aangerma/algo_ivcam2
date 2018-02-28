xL = [40 40 4000   -3  -3];
xH = [90 90 6000    3   3];
nFov = 20;
nDelay = 20;
nZ = 3;
resStruct = Calibration.calibrationGridSearch(xL,xH,nFov,nDelay,nZ);
save 'X:\Users\tmund\Calibration\resSturctOptFull.mat' 'resStruct'


%% for each delay: Plot eAlex as a function of the fovX and fovY (Using zenith values 0):
eA = resStruct.eAlex;
fX = resStruct.fX;
fY = resStruct.fY;
zX = resStruct.zX;
zY = resStruct.zY;

fXVec = resStruct.varsVecs{1};
fYVec = resStruct.varsVecs{2};
vDelay = resStruct.varsVecs{3};
zenVec = resStruct.varsVecs{4};
zen0 = find(zenVec == 0);
figure
for de = 1:nDelay
    tabplot(vDelay(de));
    surf(fX(:,:,de,zen0,zen0),fY(:,:,de,zen0,zen0),eA(:,:,de,zen0,zen0));
    [mini,i] = min(vec(eA(:,:,de,zen0,zen0)));
    
    zlabel('eAlex'),xlabel('fovX'),ylabel('fovY'),title(sprintf('eAlex - opt %2.2f at: \n fX=%2.1f,fY=%2.1f,delay=%4.0f,zX=%0.1f,zY=%0.1f',mini,fX(i),fY(i),vDelay(de),0,0))
    axis([min(vFovX),max(vFovX),min(vFovY),max(vFovY),min(eA(:)),max(eA(:))])
end

%% for each delay, get the best fov params given zenith 0 and plot the eAlex as a function of the zenith.
figure
for de = 1:nDelay
    tabplot(vDelay(de));
    [~,i] = min(vec(eA(:,:,de,zen0,zen0)));
    
    currFovX = fX(:,:,de,zen0,zen0);
    bestFovX = currFovX(i);
    fovXI = find(fXVec == bestFovX);
    currFovY = fY(:,:,de,zen0,zen0);
    bestFovY = currFovY(i);
    fovYI = find(fYVec == bestFovY);
    
    surf(squeeze(zX(fovXI,fovYI,de,:,:)),squeeze(zY(fovXI,fovYI,de,:,:)),squeeze(eA(fovXI,fovYI,de,:,:)));
    [mini,i] = min(vec(eA(fovXI,fovYI,de,:,:)));
    zlabel('eAlex'),xlabel('zenithX'),ylabel('zenithY'),title(sprintf('eAlex - opt %2.2f at: \n fX=%2.1f,fY=%2.1f,delay=%4.0f,zX=%0.1f,zY=%0.1f',...
                                                        mini,bestFovX,bestFovY,vDelay(de),zX(i),zY(i)))
    axis([min(zX(:)),max(zX(:)),min(zY(:)),max(zY(:)),min(eA(:)),max(eA(:))])
end

%% for each initialization of fovX,fovY and delay - show an arrow from xo to xopt

x0 = resStruct.optim.inputX0(:,1:3);
xopt = resStruct.optim.outputX(:,1:3);
quiver3(x0(:,1),x0(:,2),x0(:,3),xopt(:,1)-x0(:,1),xopt(:,2)-x0(:,2),xopt(:,3)-x0(:,3))

