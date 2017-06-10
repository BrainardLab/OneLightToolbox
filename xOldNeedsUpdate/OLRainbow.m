function varargout = OLRainbow(varargin)
% OLRAINBOW MATLAB code for OLRainbow.fig
%      OLRAINBOW, by itself, creates a new OLRAINBOW or raises the existing
%      singleton*.
%
%      H = OLRAINBOW returns the handle to a new OLRAINBOW or the handle to
%      the existing singleton*.
%
%      OLRAINBOW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OLRAINBOW.M with the given input arguments.
%
%      OLRAINBOW('Property','Value',...) creates a new OLRAINBOW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before OLRainbow_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to OLRainbow_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help OLRainbow

% Last Modified by GUIDE v2.5 10-Oct-2011 15:07:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OLRainbow_OpeningFcn, ...
                   'gui_OutputFcn',  @OLRainbow_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before OLRainbow is made visible.
function OLRainbow_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to OLRainbow (see VARARGIN)

% Choose default command line output for OLRainbow
handles.output = hObject;

% Make sure we're not connected to the OneLight device.
OneLight('CloseAll');
pause(2);

% Open up the OneLight device.
fprintf('- Opening OneLight device...');
OneLight('Open', 0);
fprintf('Done\n');

% Connect to the OmniDriver.
params.od = OmniDriver;

% Set the device info panel data.
set(handles.OLSerial, 'String', OneLight('GetSerialNumber', 0));
set(handles.ODDevice, 'String', params.od.SpectrometerType);
set(handles.ODSerial, 'String', params.od.SerialNumber);
set(handles.ODFirmwareVersion, 'String', params.od.FirmwareVersion);

% Set the current OneLight lamp power.
lampCurrent = OneLight('GetLampCurrent', 0);
set(handles.LampPower, 'String', sprintf('%d', lampCurrent));
set(handles.LampPowerSlider, 'Value', lampCurrent);

params.numCols = OneLight('GetNumCols', 0);

% Store program data.
setappdata(handles.MainFigure, 'params', params);

% Setup the column sliders.
colWidth = 10;
set(handles.NumColsSlider, 'SliderStep', [1/params.numCols 0.1]);
set(handles.NumColsSlider, 'Min', 1);
set(handles.NumColsSlider, 'Max', params.numCols);
set(handles.NumColsSlider, 'Value', colWidth);
ColPositionSlider_Callback(handles.ColPositionSlider, eventdata, handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes OLRainbow wait for user response (see UIRESUME)
% uiwait(handles.MainFigure);


% --- Outputs from this function are returned to the command line.
function varargout = OLRainbow_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function OLSerial_Callback(hObject, eventdata, handles)
% hObject    handle to OLSerial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of OLSerial as text
%        str2double(get(hObject,'String')) returns contents of OLSerial as a double


% --- Executes during object creation, after setting all properties.
function OLSerial_CreateFcn(hObject, eventdata, handles)
% hObject    handle to OLSerial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ODDevice_Callback(hObject, eventdata, handles)
% hObject    handle to ODDevice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ODDevice as text
%        str2double(get(hObject,'String')) returns contents of ODDevice as a double


% --- Executes during object creation, after setting all properties.
function ODDevice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ODDevice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ODSerial_Callback(hObject, eventdata, handles)
% hObject    handle to ODSerial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ODSerial as text
%        str2double(get(hObject,'String')) returns contents of ODSerial as a double


% --- Executes during object creation, after setting all properties.
function ODSerial_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ODSerial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ODFirmwareVersion_Callback(hObject, eventdata, handles)
% hObject    handle to ODFirmwareVersion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ODFirmwareVersion as text
%        str2double(get(hObject,'String')) returns contents of ODFirmwareVersion as a double


% --- Executes during object creation, after setting all properties.
function ODFirmwareVersion_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ODFirmwareVersion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object deletion, before destroying properties.
function MainFigure_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to MainFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Close the OneLight device.
fprintf('- Closing OneLight device...');
OneLight('Close', 0);
fprintf('Done\n');


% --- Executes on slider movement.
function LampPowerSlider_Callback(hObject, eventdata, handles)
% Get the slider position.
sliderPosition = round(get(hObject, 'Value'));

% Set the lamp current.
OneLight('SetLampCurrent', 0, sliderPosition);

% Update the info box.
set(handles.LampPower, 'String', sprintf('%d', sliderPosition));


% --- Executes during object creation, after setting all properties.
function LampPowerSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LampPowerSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function LampPower_Callback(hObject, eventdata, handles)
% Get the contents of the box.
lampPower = get(hObject, 'String');

% Convert the string into a scalar.
lampPower = round(str2double(lampPower));

% Limit the lamp power's bounds.
if lampPower < 0
	lampPower = 0;
elseif lampPower > 255
	lampPower = 255;
end

% Update the box.
set(hObject, 'String', sprintf('%d', lampPower));

% Update the slider.
set(handles.LampPowerSlider, 'Value', lampPower);

% Update the actual lamp current.
OneLight('SetLampCurrent', 0, lampPower);


% --- Executes during object creation, after setting all properties.
function LampPower_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LampPower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function NumColsSlider_Callback(hObject, eventdata, handles)
% hObject    handle to NumColsSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the column position callback.
ColPositionSlider_Callback(handles.ColPositionSlider, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function NumColsSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NumColsSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function ColPositionSlider_Callback(hObject, eventdata, handles)
% hObject    handle to ColPositionSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

params = getappdata(handles.MainFigure);

% Get the current slider position.
pos = round(get(hObject, 'Value'));

% Get current numcols slider value.
colWidth = round(get(handles.NumColsSlider, 'Value'));

% Re-calculate the min and max values for the position slider.
minVal = ceil(colWidth/2);
maxVal = params.numCols - floor(colWidth/2);
sliderRange = maxVal - minVal;
set(handles.ColPositionSlider, 'Min', minVal);
set(handles.ColPositionSlider, 'Max', maxVal);
set(handles.ColPositionSlider, 'SliderStep', [1/sliderRange 1/sliderRange]);

% Re-center the slider.
if pos < (minVal + colWidth/2)
	pos = floor(minVal + colWidth/2);
	


set(handles.ColPositionSlider, 'Value', params.numCols/2);

% Determine our column range.
startCol = pos - colWidth/2 + 1
endCol = pos + colWidth/2

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function ColPositionSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ColPositionSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1
