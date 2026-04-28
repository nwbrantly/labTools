function COP = computeCOP(grfDataSlow, grfDataFast, slowLeg, fastLeg)
%COMPUTECOP Compute bilateral center of pressure in lab coordinates.
%
%   Computes the instantaneous center of pressure (COP) from bilateral
% ground reaction force (GRF) data. Each leg's COP is computed in
% force plate coordinates and then transformed to lab coordinates using
% plate-specific calibration matrices. The combined COP is a vertical-
% force-weighted average of the two leg COPs.
%
% Inputs:
%   grfDataSlow - N-by-5 matrix of GRF data for the slow-leg force
%                 plate [Fx Fy Fz Mx My] in force plate coordinates
%   grfDataFast - N-by-5 matrix of GRF data for the fast-leg force
%                 plate [Fx Fy Fz Mx My] in force plate coordinates
%   slowLeg     - char 'L' or 'R' identifying the slow-leg plate
%   fastLeg     - char 'L' or 'R' identifying the fast-leg plate
%
% Outputs:
%   COP - 3-by-N matrix of combined COP position in lab coordinates
%
% Toolbox Dependencies:
%   None
%
% See also COMPUTEFORCEPARAMETERS, COMPUTECOM.

arguments
    grfDataSlow (:,:) double
    grfDataFast (:,:) double
    slowLeg     (1,1) char
    fastLeg     (1,1) char
end

%% Force Plate Transformation Matrices
% NOTE: Calibration matrices encode lab-specific force plate positions
% and orientations on the instrumented treadmill; do not modify.
LTransformationMatrix = [ ...
    1,    0,  0,  0; ...
    20,   1,  0,  0; ...
    1612, 0, -1,  0; ...
    0,    0,  0, -1];
RTransformationMatrix = [ ...
    1,     0,  0,  0; ...
    -944, -1,  0,  0; ...
    1612,  0, -1,  0; ...
    0,     0,  0, -1];

eval(['slowTransMat=' slowLeg 'TransformationMatrix(2:end, 2:end);']);
eval(['fastTransMat=' fastLeg 'TransformationMatrix(2:end, 2:end);']);
eval(['slowTransVec=' slowLeg 'TransformationMatrix(2:end, 1);']);
eval(['fastTransVec=' fastLeg 'TransformationMatrix(2:end, 1);']);

%% Compute COP for Slow Leg
% COP formula: [-h*F + M] ./ Fz, h = 5 mm (plate surface to sensor height)
copSlow(:, 2) = ...
    (-5*grfDataSlow(:, 2) + grfDataSlow(:, 4)) ./ grfDataSlow(:, 3);
copSlow(:, 1) = ...
    (-5*grfDataSlow(:, 1) - grfDataSlow(:, 5)) ./ grfDataSlow(:, 3);
copSlow(:, 3) = 0;
copSlow = bsxfun(@plus, slowTransMat*copSlow', slowTransVec);
fzSlow  = grfDataSlow(:, 3);

%% Compute COP for Fast Leg
copFast(:, 2) = ...
    (-5*grfDataFast(:, 2) + grfDataFast(:, 4)) ./ grfDataFast(:, 3);
copFast(:, 1) = ...
    (-5*grfDataFast(:, 1) - grfDataFast(:, 5)) ./ grfDataFast(:, 3);
copFast(:, 3) = 0;
copFast = bsxfun(@plus, fastTransMat*copFast', fastTransVec);
fzFast  = grfDataFast(:, 3);

%% Compute Combined COP
% Weighted average of each leg's COP by its vertical force
COP = bsxfun(@rdivide, ...
    bsxfun(@times, copFast, fzFast') + ...
    bsxfun(@times, copSlow, fzSlow'), ...
    fzSlow' + fzFast');

end

