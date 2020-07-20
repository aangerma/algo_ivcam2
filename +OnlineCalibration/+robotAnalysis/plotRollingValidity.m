
function plotRollingValidity(res,imagePath,showPlot)

    % Save Validity flags for dbg
    inputValidityDbg = getFields(res,'dbgRerun','inputValidityDbg');
    fields = fieldnames(inputValidityDbg);
    
    extraFields = {'validMovement';'validFixBySVM'};
    for k = 1:numel(extraFields)
        extras(k,:) = getFields(res,'dbgRerun',extraFields{k});
    end
    logicNames = {};
    for f = 1:numel(fields)
        val = inputValidityDbg.(fields{f});
        if islogical(val)
            logicNames{numel(logicNames)+1} = fields{f};
        end
    end
    if showPlot
        ff = figure('visible','on','units','normalized','outerposition',[0 0 1 1]);
    else
        ff = Calibration.aux.invisibleFigure;
    end
    for f = 1:numel(logicNames)
        values = getFields(res,'dbgRerun','inputValidityDbg',logicNames{f});
        subplot(numel(logicNames)+numel(extraFields),1,f);
        scatter(1:numel(values), values, 50, [0,255,0].*values', 'filled');
        xlabel('Iter');
        title(logicNames{f});
    end
    for f = 1:numel(extraFields)
        values = extras(f,:);
        subplot(numel(logicNames)+numel(extraFields),1,f+numel(logicNames));
        scatter(1:numel(values), values, 50, [0,255,0].*values', 'filled');
        xlabel('Iter');
        title(extraFields{f});
    end
    if ~isempty(imagePath)
        set(0, 'currentfigure', ff);
        saveas(ff,imagePath)
        if ~showPlot
            close(ff);
        end
    end