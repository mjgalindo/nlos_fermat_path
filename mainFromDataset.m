clear;
clc;
close all;
addpath(genpath('./'));

% Set the path to the nlos-framework utilities for matlab
addpath('../nlos-framework/reconstruct/matlab');

% Try simple files if you want to recognize the reconstruction
filename = 'DATASET FILE';
prefix = 'PATH TO THE PREVIOUS FILE';


actual_file = [prefix, filename];
fprintf('Loading dataset %s', actual_file);
ds = NLOSData(actual_file, 'bounces', 'sum', 'shifttime', true);
detGridSizeCamera = double(ds.CameraGridPoints);
detGridSizeLaser = double(ds.LaserGridPoints);

% Change the depth dimension to the Z axis
detGridSize = detGridSizeCamera;
Y = ds.CameraGridPositions(:,:,2);
ds.CameraGridPositions(:,:,2) = ds.CameraGridPositions(:,:,3);
ds.CameraGridPositions(:,:,3) = Y;
Y = ds.LaserGridPositions(:,:,2);
ds.LaserGridPositions(:,:,2) = ds.LaserGridPositions(:,:,3);
ds.LaserGridPositions(:,:,3) = Y;
clear Y
detLocs = double(reshape(ds.CameraGridPositions, [prod(detGridSizeCamera), 3]));
srcLoc = double(reshape(ds.LaserGridPositions, [prod(detGridSizeLaser), 3]));

if ds.IsConfocal
    pts = prod(ds.CameraGridPoints);
else
    pts = prod(ds.CameraGridPoints)*prod(ds.LaserGridPoints);
end

transients = double(reshape(ds.Data, pts, []));
T = size(transients, 2);
temporalBinCenters = linspace(0, T*ds.DeltaT, T);
whetherConfocal = ds.IsConfocal;       % whether confocal setting (colocated virtual source and detecotr)

% transients = transients(:,1:510);
% temporalBinCenters = temporalBinCenters(1:510);
clear ds;
% parameters
folderData            = './data';
folderReconstruction  = './reconstructions';


%% ===== detecting discontinuities in transients =====
% ----- parameters -----
discontDetectionPara.expCoeff             = [0.3];       % model the exponential falloff of the SPAD signal
discontDetectionPara.sigmaBlur            = [1];         % Difference of Gaussian, standard deviation
discontDetectionPara.numOfDiscont         = 2;           % number of discontinuities per transient
discontDetectionPara.convolveTwoSides     = true;        % convolve transient with DoG filter in both sides (for detecting local minimum/maximum)
discontDetectionPara.whetherSortDisconts  = true;        % whether sort discontinuities

% ----- pathlength discontinuties visualization  -----
whetherVisualizePDSurface       = true;
whetherVisualizePDIndivisually  = false;
visualizaRange                  = 1:2000;

detectDiscontinuity;

%% ===== Fermat Flow (sphere-ray intersection) =====
% ----- parameters for computing x and y derivatives -----
pathSurfaceDerivativePara.detGridSize              = detGridSize;
pathSurfaceDerivativePara.planeFittingRange        = 5;           % local 5*5 patch for estimating x and y derivatives, odd number, at least 3
pathSurfaceDerivativePara.spatialSigma             = 4;           % bilateral filtering, spatial gaussian blur kernel size
pathSurfaceDerivativePara.diffSigma                = 10;          % bilateral filtering, range gaussian blur kernel size
pathSurfaceDerivativePara.fitErrorThreshold        = Inf;         % reconstruction threshold, larger the value, looser the constraint
pathSurfaceDerivativePara.curvatureRatioThreshold  = 0;           % reconstruction threshold, smaller the value, looser the constraint

% ----- x, y derivatives visualization -----
whetherVisualizexDyDzD = true;

fermatFlowReconstruction;
