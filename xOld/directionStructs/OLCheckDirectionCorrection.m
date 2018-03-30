function OLCheckDirectionCorrection(directionStruct)
% Check how well correction of a directionStruct worked.
%
% Syntax:
%    OLCheckDirectionCorrection(protocolParams)
%
% Description:
%    This script analyzes the output of the procedure that tunes up the primaries based on 
%    a measurement/update loop.  Its main purpose in life is to help us debug the procedure,
%    running it would not be a normal part of operation, as long as the validations come out well.
%
% Input:
%    correctedDirection - a directionStruct which has been corrected (i.e.,
%                         run through OLCorrectDirection). This will have
%                         three separate structures under
%                         .describe.correction, one for the background,
%                         directionPositive and directionNegative. These
%                         structures contain the debugging data from
%                         OLCorrectPrimaryValues.
%
% Output:
%    None.
%
% Optional key/value pairs:
%    None.
%
% See also:
%    OLCheckPrimaryCorrection, OLCorrectDirection, OLCorrectPrimaryValues

% History:
%    02/13/18  jv   Wrapper around old function, to make it work with
%                   directionStructs
