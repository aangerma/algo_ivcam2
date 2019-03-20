function [ f ] = invisibleFigure(  )
%INVISIBLEFIGURE creates a handle for an invisible figure
f = figure('visible','off','units','normalized','outerposition',[0 0 1 1]);
end
