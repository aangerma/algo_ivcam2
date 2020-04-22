classdef FrameDsmWarper
    % FrameDsmWarper
    %   Applies DSM polynomial manipulation to frames.
    % Usage:
    %   1) obj = FrameDsmWarper(accPath)
    %       Generates the object.
    %       accPath is a full path to ACC, not including the internal Matlab folder.
    %   2) obj = obj.SetRes(frameSize)
    %       Generates a pixel-to-DSM mapping.
    %       frameSize = [yRes, xRes]
    %   3) obj = obj.SetDsmWarp(dsmWarpCoefX, dsmWarpCoefY)
    %       Generates the warper.
    %       dsmWarpCoefX/Y are polynomial coefficients for manipulating DSMx and DSMy (use [1,0] and [1,0] for the dummy warper).
    %   4) warpedFrame = obj.ApplyWarp(frame)
    %       Warps the frame.
    
    properties
        baselineRegs    = struct('hbaseline', 0, 'baseline', -10, 'baseline2', 100);
        calData         = []; % calibration data (from specific ACC)
        frameSize       = []; % [yRes, xRes]
        Kworld          = []; % 3x3 intrinsic matrix
        rpt             = []; % Nx3 structure of [RTD, DSMx, DSMy]
        dsmWarpCoefX    = []; % polynomial coefficients for DSMx
        dsmWarpCoefY    = []; % polynomial coefficients for DSMy
        xyResampling    = []; % [yRes x xRes x 2] pixel coordinates
        warper          = []; % warping engine
    end
    
    methods
        
        function obj = FrameDsmWarper(accPath) % loads calibration data
            fprintf('Extracting calibration data... (wait a second)\n');
            obj.calData = Calibration.tables.getCalibDataFromCalPath([], accPath);
            obj.calData.regs.DEST = mergestruct(obj.calData.regs.DEST, obj.baselineRegs);
        end
        
        function obj = SetRes(obj, frameSize) % generates pixel-to-DSM mapping
            fprintf('Mapping pixels to DSM... (wait 10 seconds)\n');
            obj.frameSize = frameSize;
            obj.Kworld = Pipe.calcIntrinsicMat(obj.calData.regs, obj.frameSize);
            [y, x] = ndgrid(1:obj.frameSize(1), 1:obj.frameSize(2));
            vertices = [x(:), y(:), ones(prod(obj.frameSize),1)] * (inv(obj.Kworld))' * 1e3;
            obj.rpt = Utils.convert.RptToVertices(vertices, obj.calData.regs, obj.calData.tpsUndistModel, 'inverse');
        end
        
        function obj = SetDsmWarp(obj, dsmWarpCoefX, dsmWarpCoefY) % calculates the resampling coordinates and generates the warper
            assert(~isempty(obj.frameSize), 'Pixels mapping not defined. Use SetRes prior to setting the DSM warper.')
            fprintf('Generating warping engine... (wait a minute)\n');
            obj.dsmWarpCoefX = dsmWarpCoefX;
            obj.dsmWarpCoefY = dsmWarpCoefY;
            rptDist = [obj.rpt(:,1), polyval(obj.dsmWarpCoefX, obj.rpt(:,2)), polyval(obj.dsmWarpCoefY, obj.rpt(:,3))];
            verticesDist = Utils.convert.RptToVertices(rptDist, obj.calData.regs, obj.calData.tpsUndistModel, 'direct');
            pixelsDist = (verticesDist./verticesDist(:,3)) * obj.Kworld';
            xDist = reshape(pixelsDist(:,1), obj.frameSize);
            yDist = reshape(pixelsDist(:,2), obj.frameSize);
            obj.xyResampling = cat(3, xDist, yDist);
            obj.warper = @(im) du.math.imageWarp(im, obj.xyResampling(:,:,2), obj.xyResampling(:,:,1));
        end
        
        function warpedFrame = ApplyWarp(obj, frame)
            assert(~isempty(obj.warper), 'Warper not defined. Use SetDsmWarp prior to applying the warper.')
            fnames = fieldnames(frame);
            for iField = 1:length(fnames)
                if strcmp(fnames{iField},'z') || strcmp(fnames{iField},'i') || strcmp(fnames{iField},'c')
                    warpedFrame.(fnames{iField}) = cast(obj.warper(double(frame.(fnames{iField}))), class(frame.(fnames{iField})));
                else
                    warpedFrame.(fnames{iField}) = frame.(fnames{iField});
                end
            end
        end
        
    end
    
end
