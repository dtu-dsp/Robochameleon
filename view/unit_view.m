%> @file unit_view.m
%> @brief Superclass: graphical interface for units
%>
%> @class unit_view
%> @brief Superclass: graphical interface for units
%> 
%> This class creates the graphical interface which enables the user
%> to view signals traversing through a unit and copy them to the
%> workspace.
%> DebugMode is supposed to be turned on.
%> @code
%> setpref('robochameleon','debugMode',true);
%> @endcode
%>
%> @author Rasmus Jones
%> @version 1
classdef unit_view   
    properties(GetAccess=private,SetAccess=private,Hidden)
        %> Next nodes which hold the traversed signals of this block
        nextNodes;
        %> Input destination of the corresponding next node
        destInputs;
        %> Label of the unit
        label;
        %> Debug mode
        debugMode;
    end
    
    methods
        function obj=unit_view(nextNodes,destInputs,label)
           % Setter
           obj.nextNodes    = nextNodes;
           obj.destInputs   = destInputs;
           obj.label        = label;
             
           % Create GUI and populate
           obj.createUI();         
           
        end
        
        
    end
    methods (Access=public)
        %> @brief Callback function when clicked on the disp() button
        %>
        %> Displays the selected signals in the console
        %>
       function select(obj,~,~,ui)
            list = ui.listbox.Value;
            N    = length(list);
            for i=1:N
                fprintf('\n%s:\n',[obj.label ' --> ' obj.nextNodes{i}.label '[' num2str(obj.destInputs(i)) ']']);
                disp(obj.nextNodes{list(i)}.inputBuffer{obj.destInputs(list(i))});
            end
       end
        %> @brief Callback function when clicked on the Copy to workspace as cell button
        %> 
        %> Saved the selected signals to the workspace in form of a cell
        %> named sig
        %>
        function copy2Cell(obj,~,~,ui)
            list = ui.listbox.Value;
            N    = length(list);
            sig = cell(1,N);
            for i=1:N
                sig{i}=obj.nextNodes{list(i)}.inputBuffer{obj.destInputs(list(i))};
            end
            assignin('base','sig',sig)
            fprintf('Saved chosen signals to workspace as cell (1,%g).\n',N)
        end
        %> @brief Callback function when clicked on the plot() button
        %> 
        %> (TODO) This should plot the selected signals in time domain
        %> 
        function plotTime(obj,~,~,ui)
            list = ui.listbox.Value;
            N    = length(list);
            sig = zeros(obj.nextNodes{1}.inputBuffer{list(1)}.L,N);
            for i=1:length(list)
                sig(:,i)=get(obj.nextNodes{list(i)}.inputBuffer{list(i)});
            end
            t = 0:obj.nextNodes{list(1)}.inputBuffer{list(1)}.Ts:(obj.nextNodes{list(1)}.inputBuffer{list(1)}.L-1)*obj.nextNodes{list(1)}.inputBuffer{list(1)}.Ts;
            figure()
            plot(t,sig);
            xlabel('Time');
            ylabel('Magnitude');
            title(obj.label);
        end
        %> @brief Callback function when clicked on the plot(fft()) button
        %> 
        %> (TODO) This should plot the selected signals in frequency domain
        %> 
        function plotFreq(obj,~,~,ui)
            list = ui.listbox.Value;
            N    = length(list);
            sig = zeros(obj.nextNodes{1}.inputBuffer{list(1)}.L,N);
            for i=1:length(list)
                sig(:,i)=get(obj.nextNodes{list(i)}.inputBuffer{list(i)});
            end
            f = linspace(-1/obj.nextNodes{list(1)}.inputBuffer{list(1)}.Ts/2,1/obj.nextNodes{list(1)}.inputBuffer{list(1)}.Ts/2,obj.nextNodes{list(1)}.inputBuffer{list(1)}.L);
            SIG = abs(fftshift(fft(sig))).^2;
            figure()
            plot(f,SIG);
            xlabel('Frequency');
            ylabel('Power');
            title(obj.label);
        end 
    end
    methods (Access=private)
        %> @brief Creates the UI elements and populates it
        %> 
        %> Creates the UI elements and populates it with the signals
        %> traversing the unit
        %>
        function ui = createUI(obj)
           % Create and then hide the UI as it is being constructed.
           f = figure('Visible','off',...
                      'Name',obj.label,...
                      'NumberTitle','off',...
                      'MenuBar', 'none',...
                      'ToolBar', 'none');
           ratioW = 0.3;
           ratioH = 0.3;
           scrsz = get(0,'ScreenSize');
           set(gcf,'OuterPosition',[1 scrsz(4)*(1-ratioH) scrsz(3)*ratioW scrsz(4)*ratioH ])
           pos = get(gcf,'Position');
           w = pos(3);
           h = pos(4);
           ui=struct;
           N=numel(obj.nextNodes);
           popupmenu_data = cell(1,N);
           for i=1:N
           	popupmenu_data{i} = [obj.label ' --> ' obj.nextNodes{i}.label '[' num2str(obj.destInputs(i)) ']'];
           end
           if(isempty(popupmenu_data) || (~ispref('robochameleon','debugMode') || ~getpref('robochameleon','debugMode')))
               fprintf('This is a sink unit or debugMode is turned off.\n')
               enablebtn = 'off';
           else
               enablebtn = 'on';
           end
           ui.listbox = uicontrol('Style','listbox',...
                                  'String',popupmenu_data,...
                                  'max',100,...
                                  'min',1,...
                                  'Position',[0 h-285 200 285]);
           ui.showbtn = uicontrol('Style', 'pushbutton',...
                                  'String', 'disp()',...
                                  'Position', [210 h-25 160 25],...
                                  'Enable',enablebtn,...
                                  'Callback', @(hObject,callbackdata) obj.select(hObject,callbackdata,ui));
%            ui.timebtn = uicontrol('Style', 'pushbutton',...
%                                   'String', 'plot(t,sig) (TODO)',...
%                                   'Position', [210 3*28 160 25],...
%                                   'Enable','off',...
%                                   'Callback', @(hObject,callbackdata) obj.plotTime(hObject,callbackdata,ui));
%            ui.freqbtn = uicontrol('Style', 'pushbutton',...
%                                   'String', 'plot(f,fft(sig)) (TODO)',...
%                                   'Position', [210 2*28 160 25],...
%                                   'Enable','off',...
%                                   'Callback', @(hObject,callbackdata) obj.plotFreq(hObject,callbackdata,ui));
%            ui.workspacebtn1 = uicontrol('Style', 'pushbutton',...
%                                   'String', 'Copy to workspace as matrix',...
%                                   'Position', [210 28 160 25],...
%                                   'Enable',enablebtn,...
%                                   'Callback', @(hObject,callbackdata) obj.copy2Mat(hObject,callbackdata,ui));
           ui.workspacebtn2 = uicontrol('Style', 'pushbutton',...
                                  'String', 'Copy to workspace as cell',...
                                  'Position', [210 h-25-1*28 160 25],...
                                  'Enable',enablebtn,...
                                  'Callback', @(hObject,callbackdata) obj.copy2Cell(hObject,callbackdata,ui));
           % Make the UI visible.
           f.Visible = 'on';
           
        end        
    end
end

