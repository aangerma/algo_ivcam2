function [t0,dt,v]=readScopeHDF5data(fn,chan)
%fn - file name
%chan - scop channel


hi = hdf5info(fn);
if(length(hi.GroupHierarchy.Groups)~=3)
    return;
end

nsig = length(hi.GroupHierarchy.Groups(3).Groups);

if(chan<=0 || chan>nsig)
    error('Bad channel');
end
% [{hi.GroupHierarchy.Groups(3).Groups(1).Attributes.Name}' {hi.GroupHierarchy.Groups(3).Groups(1).Attributes.Value}']
axisTransStringNames = {'YOrg','XOrg','YInc','XInc'};
axisTransData=struct;
for j = 1:length(axisTransStringNames)
    fieldIndx = arrayfun(@(i) find(cellfun(@(X) ~isempty(X),strfind({hi.GroupHierarchy.Groups(3).Groups(i).Attributes.Name},axisTransStringNames{j}))),1:nsig);
    assert(length(unique(fieldIndx))==1);
    fieldIndx=fieldIndx(1);
    axisTransData.(axisTransStringNames{j})=fieldIndx;
    
end

v0=hi.GroupHierarchy.Groups(3).Groups(chan).Attributes(axisTransData.YOrg).Value;
dv=hi.GroupHierarchy.Groups(3).Groups(chan).Attributes(axisTransData.YInc).Value;

t0=hi.GroupHierarchy.Groups(3).Groups(chan).Attributes(axisTransData.XOrg).Value;
dt=hi.GroupHierarchy.Groups(3).Groups(chan).Attributes(axisTransData.XInc).Value;
v = double(hdf5read(hi.GroupHierarchy.Groups(3).Groups(chan).Datasets(1)))*dv+v0;
end