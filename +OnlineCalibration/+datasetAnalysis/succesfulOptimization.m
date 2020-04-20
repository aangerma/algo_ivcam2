function succes = succesfulOptimization(uvPre,uvPost,successFunc)

succes = uvPost(:) <= interp1(successFunc(:,1),successFunc(:,2),uvPre(:),'linear');

end