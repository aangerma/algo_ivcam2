function res = calcCoeff(calibParams)
tab = calibParams.fovExpander.table;


angIn = tab(:,1);
angOut = tab(:,2);

modelFunc = @(x) applyModel(angIn,angOut,x);

[xbest,err] = fminsearch(modelFunc,[0,0,0]');

angOutHat = angIn + angIn.^[2,4,6]*xbest;
figure;
plot(tab(:,1),tab(:,2));
hold on
plot(tab(:,1),angOutHat);
end
function err = applyModel(angIn,angOut,x)
    angOutHat = angIn + angIn.^[2,4,6]*x;

    err = norm(angOutHat-angOut);
    
end