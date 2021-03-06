function varargout = kp_menu(varargin)
% KP_MENU MATLAB code for kp_menu.fig
%      KP_MENU, by itself, creates a new KP_MENU or raises the existing
%      singleton*.
%
%      H = KP_MENU returns the handle to a new KP_MENU or the handle to
%      the existing singleton*.
%
%      KP_MENU('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in KP_MENU.M with the given input arguments.
%
%      KP_MENU('Property','Value',...) creates a new KP_MENU or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before kp_menu_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to kp_menu_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help kp_menu

% Last Modified by GUIDE v2.5 10-Oct-2016 14:33:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @kp_menu_OpeningFcn, ...
                   'gui_OutputFcn',  @kp_menu_OutputFcn, ...
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


% --- Executes just before kp_menu is made visible.
function kp_menu_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to kp_menu (see VARARGIN)

% Choose default command line output for kp_menu
handles.output = hObject;

handles.dem = varargin{1};
handles.poly = varargin{2};
handles.identifier = varargin{3};
handles.projection = varargin{4};

handles.knickpoints = [];

FD = FLOWobj(handles.dem);

% Flow Accumulation
A = flowacc(FD);

% Streams
S1 = STREAMobj(FD,A>300);

S1 = klargestconncomps(S1);

axes(handles.catchment_axes);

plot(S1);
hold on;

T = trunk(S1);
plot(T, 'k-', 'LineWidth', 2);

axes(handles.slope_axes);
h = plotdz(T, handles.dem);

elevation = get(h,'YData');
distance = get(h,'XData');

handles.FD = FD;
handles.A = A;
handles.S1 = S1;
handles.T = T;
handles.elevation = elevation;
handles.distance = distance;
handles.cDEM = handles.dem;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes kp_menu wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function process_knickpoints(handles, output_location)
    s = size(handles.knickpoints);
    stream_objs = {};
    
    for k = 1:s(1)
       kd = handles.knickpoints(k, :);
       if k < 2
            % Starting knickpoint
            S = modify(handles.T,'distance', [0, kd(5)]);
            stream_objs = [stream_objs; S];
            
       elseif k == max(s(1))
            % Last knickpoint
            kd2 = handles.knickpoints(k-1, :);
            S1 = modify(handles.T,'distance', [kd2(5), kd(5)]);
            disp(handles.distance(end))
            S2 = modify(handles.T,'distance', [kd(5), max(handles.distance)]);
            stream_objs = [stream_objs; S1; S2];
       else
            kd2 = handles.knickpoints(k-1, :);
            S = modify(handles.T,'distance', [kd2(5), kd(5)]);
            stream_objs = [stream_objs; S];
       end
    end
    
    stream_profiler(handles.poly, handles.dem, stream_objs, ...
        handles.identifier, output_location, handles.knickpoints, ...
        handles.projection, [1 1 1 1])

% --- Outputs from this function are returned to the command line.
function varargout = kp_menu_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in save_btn.
function save_btn_Callback(hObject, eventdata, handles)
% hObject    handle to save_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.knickpoints) < 1
    output_location = uigetdir;
    process_knickpoints(handles, output_location);
end

% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in select_knickpoints.
function select_knickpoints_Callback(hObject, eventdata, handles)
% hObject    handle to select_knickpoints (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cla(handles.slope_axes,'reset')
axes(handles.slope_axes);
h = plotdz(handles.T, handles.dem);

[x,y]= getpts;

cla(handles.catchment_axes,'reset');

axes(handles.catchment_axes);

plot(handles.S1);
hold on;

plot(handles.T, 'k-', 'LineWidth', 2);

kp_data = [];

for k=1:length(x)
	x1 = x(k);
	y1 = y(k);

    xdiff = abs(handles.distance'-x1);
    ydiff = abs(handles.elevation'-y1);
    
    [~, xI] = min(xdiff+ydiff);
    
    axes(handles.slope_axes);
    hold on;
    
    plot(handles.distance(xI), handles.elevation(xI), 'rd');
    
    lx = length(handles.T.x);
    coordX = handles.T.x(lx-xI);
    coordY = handles.T.y(lx-xI);
    axes(handles.catchment_axes);
    
    kp_data = [kp_data; [coordX, coordY, lx-xI, xI, handles.distance(xI), handles.elevation(xI)]];
    
    hold on;
    
    plot(coordX, coordY, 'rd');
end

handles.knickpoints = kp_data;
guidata(handles.output, handles);

% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function name_box_Callback(hObject, eventdata, handles)
% hObject    handle to name_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of name_box as text
%        str2double(get(hObject,'String')) returns contents of name_box as a double


% --- Executes during object creation, after setting all properties.
function name_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to name_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function notes_box_Callback(hObject, eventdata, handles)
% hObject    handle to notes_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of notes_box as text
%        str2double(get(hObject,'String')) returns contents of notes_box as a double


% --- Executes during object creation, after setting all properties.
function notes_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to notes_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
