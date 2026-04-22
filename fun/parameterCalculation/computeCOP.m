function COP = computeCOP(GRFDataS, GRFDataF, s, f)
LTransformationMatrix = [1, 0, 0, 0; 20, 1, 0, 0; 1612, 0, -1, 0; 0, 0, 0, -1];
RTransformationMatrix = [1, 0, 0, 0; -944, -1, 0, 0; 1612, 0, -1, 0; 0, 0, 0, -1];
eval(['STransformationMatrix=' s 'TransformationMatrix(2:end, 2:end);']);
eval(['FTransformationMatrix=' f 'TransformationMatrix(2:end, 2:end);']);
eval(['STransformationVec=' s 'TransformationMatrix(2:end, 1);']);
eval(['FTransformationVec=' f 'TransformationMatrix(2:end, 1);']);

relGRF = GRFDataS;
COPS(:, 2) = (-5*relGRF(:, 2) + relGRF(:, 4))./relGRF(:, 3);
COPS(:, 1) = (-5*relGRF(:, 1) - relGRF(:, 5))./relGRF(:, 3);
COPS(:, 3) = 0;
COPS = bsxfun(@plus, STransformationMatrix*COPS', STransformationVec);

FzS = relGRF(:, 3);
relGRF = GRFDataF;
COPF(:, 2) = (-5*relGRF(:, 2) + relGRF(:, 4))./relGRF(:, 3);
COPF(:, 1) = (-5*relGRF(:, 1) - relGRF(:, 5))./relGRF(:, 3);
COPF(:, 3) = 0;
COPF = bsxfun(@plus, FTransformationMatrix*COPF', FTransformationVec);
FzF = relGRF(:, 3);
COP = bsxfun(@rdivide,(bsxfun(@times,COPF,FzF') + bsxfun(@times,COPS,FzS')),(FzS'+FzF'));
% computeCOP  Compute bilateral center of pressure in lab coordinates.
%
%   Syntax:
%     COP = computeCOP(grfDataSlow, grfDataFast, slowLeg, fastLeg)
%
%   Computes the instantaneous center of pressure (COP) from bilateral
% ground reaction force (GRF) data. Each leg's COP is computed in
% force plate coordinates and then transformed to lab coordinates using
% plate-specific calibration matrices. The combined COP is a vertical-
% force-weighted average of the two leg COPs.
%
%   Inputs:
%     grfDataSlow - N-by-5 matrix of GRF data for the slow-leg force
%                   plate [Fx Fy Fz Mx My] in force plate coordinates
%     grfDataFast - N-by-5 matrix of GRF data for the fast-leg force
%                   plate [Fx Fy Fz Mx My] in force plate coordinates
%     slowLeg     - Char 'L' or 'R' identifying the slow-leg plate
%     fastLeg     - Char 'L' or 'R' identifying the fast-leg plate
%
%   Outputs:
%     COP - 3-by-N matrix of combined COP position in lab coordinates
%
%   Toolbox Dependencies:
%     None
%
%   See also: computeForceParameters, computeCOM

arguments
    grfDataSlow (:,:) double
    grfDataFast (:,:) double
    slowLeg     (1,1) char
    fastLeg     (1,1) char
end

end

