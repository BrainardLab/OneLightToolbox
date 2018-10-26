function tests = testOLCalibrationAddSPDToDarkLight
% Test the OLCalibrationAddSPDToDarkLight function
tests = functiontests(localfunctions);
end

function setup(testcase)
% Setup a calibration struct, with mean dark is 56x1 values of .5
calibration.computed.pr650MeanDark = .5*ones(56,1);
testcase.TestData.calibration = calibration;
end

%% Test exception throwing empty calibration
function testErrorEmptyCalibration(testcase)
calibration = struct();
SPD = ones(56,1);

verifyError(testcase,@() OLCalibrationAddSPDToDarkLight(calibration,SPD),'MATLAB:InputParser:ArgumentFailedValidation');
end

%% Test exception throwing empty input SPD
function testErrorEmptySPD(testcase)
calibration = testcase.TestData.calibration;
SPD = [];

verifyError(testcase,@() OLCalibrationAddSPDToDarkLight(calibration,SPD),'MATLAB:expectedColumn');
end

%% Test exception throwing invalid type SPD
function testErrorNonnumeric(testcase)
calibration = testcase.TestData.calibration;
SPD = '';

verifyError(testcase,@() OLCalibrationAddSPDToDarkLight(calibration,SPD),'MATLAB:invalidType');
end

%% Test exception throwing invalid dimensions SPD
function testErrorRow(testcase)
calibration = testcase.TestData.calibration;
SPD = ones(1,56);

verifyError(testcase,@() OLCalibrationAddSPDToDarkLight(calibration,SPD),'MATLAB:expectedColumn');
end

function testErrorMatrix(testcase)
calibration = testcase.TestData.calibration;
SPD = ones(56,56);

verifyError(testcase,@() OLCalibrationAddSPDToDarkLight(calibration,SPD),'MATLAB:expectedColumn');
end

function testErrorOffSize(testcase)
calibration = testcase.TestData.calibration;
SPD = ones(53,1);

verifyError(testcase,@() OLCalibrationAddSPDToDarkLight(calibration,SPD),'MATLAB:incorrectSize');
end

%% Test exception throwing invalid values SPD
function testNaNsInput(testcase)
calibration = testcase.TestData.calibration;
SPD = NaN(56,1);

verifyError(testcase,@() OLCalibrationAddSPDToDarkLight(calibration,SPD),'MATLAB:expectedNonNaN');
end

%% Test expected output for valid inputs
function testPositiveInput(testcase)
calibration = testcase.TestData.calibration;
SPD = .5*ones(56,1);

expResult = ones(56,1);
actResult = OLCalibrationAddSPDToDarkLight(calibration, SPD);
actResult = actResult.computed.pr650MeanDark;
verifyEqual(testcase,actResult,expResult);
end

function testNegativeInput(testcase)
calibration = testcase.TestData.calibration;
SPD = -1*ones(56,1);

expResult = calibration.computed.pr650MeanDark;
actResult = OLCalibrationAddSPDToDarkLight(calibration, SPD);
actResult = actResult.computed.pr650MeanDark;
verifyEqual(testcase,actResult,expResult);
end

function testZeroesInput(testcase)
calibration = testcase.TestData.calibration;
SPD = zeros(56,1);

expResult = calibration.computed.pr650MeanDark;
actResult = OLCalibrationAddSPDToDarkLight(calibration, SPD);
actResult = actResult.computed.pr650MeanDark;
verifyEqual(testcase,actResult,expResult);
end