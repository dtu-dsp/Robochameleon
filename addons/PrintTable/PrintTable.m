classdef PrintTable < handle
% PrintTable: Class that allows table-like output spaced by tabs for multiple rows.
%
% Allows to create a table-like output for multiple values and columns.
% A spacer can be used to distinguish different columns (PrintTable.ColSep) and a flag
% (PrintTable.HasHeader) can be set to insert a line of dashes after the first row.
% The table can be printed directly to the console or be written to a file.
%
% LaTeX support:
% Additionally, LaTeX is supported via the property PrintTable.Format. The default value is
% 'plain', which means simple output as formatted string. If set to 'tex', the table is printed
% in a LaTeX table environment (PrintTable.ColSep is ignored and '& ' used automatically).
%
% Cell contents:
% The cell content values can be anything that is straightforwardly parseable. You can pass
% char array arguments directly or numeric values; even function handles and classes (handle
% subclasses) can be passed and will automatically be converted to a string representation.
%
% Custom cell content formatting:
% However, if you need to have a customized string representation, you can specifiy a cell
% array of strings as the last argument, containing custom formats to apply for each passed
% argument.
% Two conditions apply for this case: 
% # There must be one format string for each columns of the PrintTable
% # The column contents and the format string must be valid arguments for sprintf.
%
% Transposing:
% An overload for the ctranspose-method of MatLab is available which easily switches rows with
% columns.
%
% Examples:
% % Simply run
% PrintTable.test_PrintTable;
% % or
% PrintTable.test_PrintTable_RowHeader_Caption;
% % or
% PrintTable.test_PrintTable_LaTeX_Export;
%
% % Or copy & paste
% t = PrintTable;
% t.addRow('123','456','789');
% t.addRow('1234567','1234567','789');
% t.addRow('1234567','12345678','789');
% t.addRow('12345678','123','789');
% % sprintf-format compatible strings can also be passed as last argument:
% % single format argument:
% t.addRow(123.456789,pi,789,{'%3.4f'});
% % custom format for each element:
% t.addRow(123.456789,pi,789,{'%3.4f','%g','format. dec.:%d'});
% t.addRow('123456789','12345678910','789');
% t.addRow('adgag',uint8(4),4.6);
% t.addRow(@(mu)mu*4+56*245647869,t,'adgag');
% t.addRow('adgag',4,4.6);
% % Call display
% t.display;
% t.HasHeader = true;
% % or simply state the variable to print
% t
%
% % Transpose the table:
% tt = t';
% tt.Caption = 'This is me, but transposed!';
% tt.print;
%
% % To use a different column separator just set e.g.
% t.ColSep = ' -@- ';
% t.display;
%
% % PrintTable with "row header" mode
% t = PrintTable('This is PrintTable-RowHeader-Caption test, created on %s',datestr(now));
% t.HasRowHeader = true;
% t.HasHeader = true;
% t.addRow('A','B','C');
% t.addRow('header-autofmt',456,789,{'%d'});
% t.addRow(1234.345,456,789,{'%2.2E','%d','%d'});
% t.addRow('header-expl-fmt',456,pi,{'%s','%d','%2.2f'});
% t.addRow('nofmt-header',456,pi,{'%d','%f'});
% t.addRow('1234567','12345','789');
% t.addRow('foo','bar',datestr(clock));
% t.display;
%
% % Latex output
% t.Format = 'tex';
% t.Caption = 'My PrintTable in LaTeX!';
% t.print;
%
% % Printing the table:
% % You can also print the table to a file. Any MatLab file handle can be used (any first
% % argument for fprintf). Run the above example, then type
% fid = fopen('mytable.txt','w');
% % [..do some printing here ..]
% t.print(fid);
% % [..do some printing here ..]
% fclose(fid);
%
% % Saving the table to a file:
% % Plaintext
% t.saveToFile('mytable_plain.txt');
% % LaTeX
% t.saveToFile('mytable_tex.tex');
% % Tight PDF
% t.saveToFile('mytable_tightpdf.pdf');
% % Whole page PDF
% t.TightPDF = false;
% t.saveToFile('mytable_tightpdf.pdf');
%
%
% @note Of course, any editor might have its own setting regarding tab
% spacing. As the default in MatLab and e.g. KWrite is four characters,
% this is what is used here. Change the TabCharLen constant to fit to your
% platform/editor/requirements.
% 
% See also: fprintf sprintf
%
% @author Daniel Wirtz @date 2011-11-17
%
% Those links were helpful for programming the PDF export:
% - http://tex.stackexchange.com/questions/2917/resize-paper-to-mbox
% - http://tex.stackexchange.com/questions/22173
% - http://www.weinelt.de/latex/
%
% @ne{0,6,dw,2012-09-19} Added printing support for function handles and improved output for
% numerical values
%
% @new{0,6,dw,2012-07-16} 
% - Added an overload for the "ctranspose" method of MatLab; now easy switching of rows and
% columns is possible. Keeping the HasHeader flag if set.
% - Fixed a problem with LaTeX export when specifying only a filename without "./" in the path
% - Made the TabCharLen a public property as MatLab behaves strange with respect to tabs for
% some reason.
%
% @change{0,6,dw,2012-06-11} 
% - Added a new property NumRows that returns the number of rows (excluding
% the header if set).
%- Made the output a bit nicer and supporting logical values now
%
% @change{0,6,dw,2012-05-04}
% - Added a property PrintTable.HasRowHeader that allows to use a single
% format specification for all row entries but the first one. Added a test
% for that.
% - A caption with sprintf-compatible arguments can be passed directly to
% the PrintTable constructor now.
% - Added support for pdf export (requires pdflatex on PATH)
% - The saveToFile method either opens a save dialog to pick a file or
% takes a filename.
% - New property PrintTable.TightPDF that determines if the pdf file
% generated for a table should be cropped to the actual table size or
% inserted into a standard article document. Having a tight pdf removes the
% caption of the table.
%
% @change{0,6,dw,2011-12-14} Added support for arrays of PrintTable instances in display, print
% and saveToFile methods.
%
% @new{0,6,dw,2011-12-01}
% - Added support for LaTeX output
% - New properties PrintTable.Format and PrintTable.Caption
% - Optional caption can be added to the Table
% - Some improvements and fixed display for some special cases
% - New PrintTable.clear method
% - Updated the documentation and test case
%
% @new{0,6,dw,2011-11-17} Added this class.
%
% This class has originally been developed as part of the framework
% KerMor - Model Order Reduction using Kernels:
% - \c Homepage http://www.agh.ians.uni-stuttgart.de/research/software/kermor.html
% - \c Documentation http://www.agh.ians.uni-stuttgart.de/documentation/kermor/
%
% Copyright (c) 2011, Daniel Wirtz
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification, are
% permitted only in compliance with the BSD license, see
% http://www.opensource.org/licenses/bsd-license.php
%
% @todo replace fprintf by sprintf and build string that can be returned by this.print and if
% no output argument is collected directly print it.
    
    properties 
	   % Equivalent length of a tab character in single-space characters
        %
        % The default value is actually read from the local MatLab
        % preferences via
        % 'com.mathworks.services.Prefs.getIntegerPref('EditorSpacesPerTab')'
        % If no value is found, 4 is used.
        %
        % @default 8 @type integer
        TabCharLen = 8; %com.mathworks.services.Prefs.getIntegerPref('EditorSpacesPerTab',4);
	   
        % A char sequence to separate the different columns.
        %
        % @default ' | ' @type char
        ColSep = ' | ';
        
        % Flag that determines if the first row should be used as table header.
        %
        % If true, a separate line with dashes will be inserted after the first printed row.
        %
        % @default false @type logical
        HasHeader = false;
        
        % Flag that determines if there is a row header for the table.
        %
        % If true, this causes a special behaviour regarding
        % formatting the the first argument passed to PrintTable.addRow.
        % Let `n` be the total number of row content arguments.
        % - No format is given: The first argument will be "stringyfied" as
        % all other elements
        % - A cell with `n=1` format strings, i.e. {'%f'}, is given: This
        % format will be applied to all but the first argument of addRow.
        % This is the actual reason why this flag was introduced, in order
        % to be able to specify a current row string header and set the
        % format for all other entries using one format string.
        % - A cell with `n-1` format strings is given: They will be applied
        % to the 2nd until last argument of addRow (in that order)
        % - A cell with `n` format strings is given: They will be applied
        % to all content arguments including the row header (in that order)
        %
        % @type logical @default false
        HasRowHeader = false;
        
        % The output format of the table when using the print method.
        %
        % Currently the values 'txt' for plaintext and 'tex' for LaTeX
        % output are available.
        %
        % @default 'txt' @type enum<'txt', 'tex'>
        Format = 'txt';
        
        % A caption for the table.
        %
        % Depending on the output the caption is added: 
        % plain: First line above table
        % tex: Inserted into the \\caption command
        %
        % @default '' @type char
        Caption = '';
        
        % Flag that indicates if exported tables in PDF format should be
        % sized to the actual table size or be contained in a normal
        % unformatted article page.
        %
        % @type logical @default true
        TightPDF = true;
    end
    
    properties(Dependent)
	   % The number of rows in the current table
	   %
	   % @type integer
        NumRows;
    end
    
    properties(SetAccess=private)
        % The string cell data
        data;
        
        % Maximum content length for each colummn
        contlen;
    end
    
    methods
        function this = PrintTable(caption, varargin)
            % Creates a new PrintTable instance.
            %
            % Parameters:
            % caption: The caption of the table. @type char @default ''
            % varargin: If given, they will be passed to sprintf using the
            % specified caption argument to create the table's Caption.
            % @type cell @default []
            this.clear;
            if nargin > 0
                if ~isempty(varargin)
                    this.Caption = sprintf(caption,varargin{:});
                else
                    this.Caption = caption;
                end
            end
        end
        
        function display(this)
            % Overload for the default builtin display method.
            %
            % Calls print with argument 1, i.e. standard output.
            for i = 1:length(this)
                this(i).print(1);
            end
        end
        
        function print(this, outfile)
            % Prints the current table to a file pointer.
            %
            % Parameters:
            % outfile: The file pointer to print to. Must either be a valid MatLab 'fileID'
            % or can be 1 or 2, for stdout or stderr, respectively. @type integer @default 1
            %
            % See also: fprintf
            if nargin == 1
                outfile = 1;
            end
            for i = 1:length(this)
                t = this(i);
                if strcmp(t.Format,'txt')
                    t.printPlain(outfile);
                elseif any(strcmp(t.Format,{'tex','pdf'}))
                    t.printTex(outfile);
                else
                    error('Unsupported format: %s',t.Format);
                end
            end
        end
        
        function saveToFile(this, filename, openfile)
            % Prints the current table to a file.
            %
            % If a file name is specified, the format is determined by the
            % file extension. Allowed types are "txt" for plain text, "tex"
            % for a LaTeX table and "pdf" for an immediate export of the
            % LaTeX table to a PDF document.
            %
            % @note The last option required "pdflatex" to be available on
            % the system's environment.
            %
            % Parameters:
            % filename: The file to print to. If the file exists, any
            % contents are discarded.
            % If the file does not exist, an attempt to create a new one is
            % made. @type char @default Prompts for saving target
            % openfile: Flag that indicates if the exported file should be
            % opened after saving. @type logical @default false
            
            % Case 1: No file name given
            if nargin < 2 || isempty(filename)
                initdir = getpref('PrintTable','LastDir',pwd);
                choices = {'*.txt', 'Text files (*.txt)';...
                           '*.tex', 'LaTeX files (*.tex)';...
                           '*.pdf', 'PDF files (*.pdf)'};
                [fname, path, extidx] = uiputfile(choices, ...
                    sprintf('Save table "%s" as',this.Caption), initdir);
                % Abort if no file was selected
                if fname == 0
                    return;
                end
                setpref('PrintTable','LastDir',path);
                ext = choices{extidx,1}(2:end);
                filename = fullfile(path, fname);
                % Take off the extension of the fname (automatically added
                % by uiputfile)
                fname = fname(1:end-4);
            % Case 2: File name given. Determine format by file
            % extension
            else
                [path, fname, ext] = fileparts(filename);
                if isempty(ext)
                    ext = ['.' this.Format];
                elseif ~any(strcmp(ext,{'.txt','.tex','.pdf'}))
                    error('Valid file formats are *.txt, *.tex, *.pdf');
                end
                if isempty(path)
                    path = '.';
                end
                % Try to create directory if not existing
                if ~isempty(path) && exist(path,'dir') ~= 7
                    mkdir(path);
                end
            end
            if nargin < 3
                openfile = false;
            end
            
            oldfmt = this.Format; % store old format
            this.Format = ext(2:end);
            % PDF export
            if strcmp(ext,'.pdf')
                this.pdfExport(path, fname);
            % Text export in either plain or LaTeX format
            else
                fid = fopen(filename,'w');
                this.print(fid);
                fclose(fid);
            end
            this.Format = oldfmt; % restore old format
            if openfile
                open(filename);
            end
        end
        
        function addRow(this, varargin)
            % Adds a row to the current table.
            %
            % Parameters:
            % varargin: Any number of arguments >= 1, each corresponding to a column of the
            % table. Each argument must be a char array.
            if isempty(varargin)
                error('Not enough input arguments.');
            end
            hasformat = iscell(varargin{end});
            if iscell(varargin{1})
                error('Invalid input argument. Cells cannot be added to the PrintTable, and if you wanted to specify a sprintf format you forgot the actual value to add.');
%             elseif hasformat && length(varargin)-1 ~= length(varargin{end})
%                 error('Input argument mismatch. If you specify a format string cell the number of arguments (=%d) to add must equal the number of format strings (=%d).',length(varargin)-1,length(varargin{end}));
            end
            if isempty(this.data)
                this.data{1} = this.stringify(varargin);
                this.contlen = ones(1,length(this.data{1}));
            else
                % Check new number of columns
                newlen = length(varargin);
                if hasformat
                    newlen = newlen-1;
                end
                if length(this.data{1}) ~= newlen 
                    error('Inconsistent row length. Current length: %d, passed: %d',length(this.data{1}),newlen);
                end
                % Add all values
                this.data{end+1} = this.stringify(varargin);
            end
            % Record content length while building the table
            this.contlen = max([this.contlen; cellfun(@length,this.data{end})]);
        end
        
        function clear(this)
            % Clears the current PrintTable contents and caption.
            this.data = {};
            this.contlen = [];
            this.Caption = '';
        end
        
        function transposed = ctranspose(this)
            transposed = this.clone;
            hlp = reshape([this.data{:}],length(this.data{1}),[]);
            transposed.data = {};
            for k=1:size(hlp,1)
                transposed.data{k} = hlp(k,:);
            end
            transposed.contlen = cellfun(@(row)max(cellfun(@(el)length(el),row)),...
                this.data);
        end
        
        function copy = clone(this)
            % Returns a new instance of PrintTable with the same content
            copy = PrintTable(this.Caption);
            copy.ColSep = this.ColSep;
            copy.HasHeader = this.HasHeader;
            copy.HasRowHeader = this.HasRowHeader;
            copy.Format = this.Format;
            copy.TightPDF = this.TightPDF;
            copy.data = this.data;
            copy.contlen = this.contlen;
        end
        
        function set.ColSep(this, value)
            if ~isempty(value) && ~isa(value,'char')
                error('ColSep must be a char array.');
            end
            this.ColSep = value;
        end
        
        function set.HasHeader(this, value)
            if ~islogical(value) || ~isscalar(value)
                error('HasHeader must be a logical scalar.');
            end
            this.HasHeader = value;
        end
        
        function set.HasRowHeader(this, value)
            if ~islogical(value) || ~isscalar(value)
                error('HasRowHeader must be a logical scalar.');
            end
            this.HasRowHeader = value;
        end
        
        function set.Caption(this, value)
            if ~isempty(value) && ~ischar(value)
                error('Caption must be a character array.');
            end
            this.Caption = value;
        end
        
        function set.Format(this, value)
            % 'Hide' the valid format pdf as its only used internally .. i
            % know .. lazyness :-)
            if ~any(strcmp({'txt','tex','pdf'},value))
                error('Format must be either ''txt'' or ''tex''.');
            end
            this.Format = value;
	   end
	   
	   function set.TabCharLen(this, value)
		  if isscalar(value) && value > 0 && round(value) == value
			 this.TabCharLen = value;
		  else
			 error('Invalid argument for TabCharLen. Must be a positive integer scalar.');
		  end
	   end
	   
        function value = get.NumRows(this)
            value = length(this.data);
            if this.HasHeader
                value = max(0,value-1);
            end
        end
    end
    
    methods(Access=private)
        
        function printPlain(this, outfile)
            % Prints the table as plain text
            if ~isempty(this.Caption)
                fprintf(outfile,'Table ''%s'':\n',this.Caption);
            end
            for ridx = 1:length(this.data)
                row = this.data{ridx};
                this.printRow(row,outfile,this.ColSep);
                fprintf(outfile,'%s\n',row{end});
                if ridx == 1 && this.HasHeader
                    % Compute number of tabs
                    ttabs = 0;
                    for i = 1:length(row)
                        ttabs = ttabs +  ceil((length(this.ColSep)*(i~=1)+this.contlen(i))/this.TabCharLen);
                    end
                    fprintf(outfile,'%s\n',repmat('_',1,(ttabs+1)*this.TabCharLen));
                end
            end
        end
        
        function printTex(this, outfile)
            % Prints the table in LaTeX format

            % Add comment
            if ~isempty(this.Caption)
                fprintf(outfile,'%% PrintTable "%s" generated on %s\n',this.Caption,datestr(clock));
            else
                fprintf(outfile,'%% PrintTable generated on %s\n',datestr(clock));
            end
            cols = 0;
            if ~isempty(this.data)
                cols = length(this.data{1});
            end
            % Only add surroundings for pure tex output or full-sized PDF
            % generation
            if strcmp(this.Format,'tex') || ~this.TightPDF
                fprintf(outfile,'\\begin{table}[!hb]\n\t\\centering\n\t');
            elseif ~isempty(this.Caption)
                % Enable this if you want, but i found no straight way of putting the caption
                % above the table (for the given time&resources :-))
                %fprintf(outfile,'Table: %s\n',this.Caption);
            end
            fprintf(outfile,'\\begin{tabular}{%s}\n',repmat('l',1,cols));
            % Print all rows
            for ridx = 1:length(this.data)
                row = this.data{ridx};
                fprintf(outfile,'\t\t');
                this.printRow(row,outfile,'& ');
                fprintf(outfile,'%s\\\\\n',row{end});
                if ridx == 1 && this.HasHeader
                    fprintf(outfile,'\t\t\\hline\\\\\n');
                end
            end
            fprintf(outfile, '\t\\end{tabular}\n');
            % Only add surroundings for pure tex output or full-sized PDF
            % generation
            if strcmp(this.Format,'tex') || ~this.TightPDF
                if ~isempty(this.Caption)
                    fprintf(outfile,'\t\\caption{%s}\n',this.Caption);
                end
                fprintf(outfile, '\\end{table}\n');
            end
        end
        
        function pdfExport(this, path, fname)
            [status, msg] = system('pdflatex --version');
            if status ~= 0
                error('pdfLaTeX not found or not working:\n%s',msg);
            else
                cap = 'table';
                if ~isempty(this.Caption)
                    cap = ['''' this.Caption ''''];
                end
                fprintf('Exporting %s to PDF using "%s"... ',cap,msg(1:strfind(msg,sprintf('\n'))-1));
            end

            texfile = fullfile(path, [fname '.tex']);
            fid = fopen(texfile,'w');
            fprintf(fid,'\\documentclass{article}\n\\begin{document}\n');
            if this.TightPDF
                fprintf(fid,'\\newsavebox{\\tablebox}\n\\begin{lrbox}{\\tablebox}\n');
            else
                fprintf(fid, '\\thispagestyle{empty}\n');
            end
            % Print actual tex table
            this.print(fid);
            if this.TightPDF
                fprintf(fid, ['\\end{lrbox}\n\\pdfhorigin=0pt\\pdfvorigin=0pt\n'...
                    '\\pdfpagewidth=\\wd\\tablebox\\pdfpageheight=\\ht\\tablebox\n'...
                    '\\advance\\pdfpageheight by \\dp\\tablebox\n'...
                    '\\shipout\\box\\tablebox\n']);
            end
            fprintf(fid,'\\end{document}');
            fclose(fid);
            [status, msg] = system(sprintf('pdflatex -interaction=nonstopmode -output-directory="%s" %s',path,texfile));
            if status ~= 0
                error('pdfLaTeX finished with errors:\n%s',msg);
            else
                %delete(texfile,fullfile(path, [fname '.aux']),fullfile(path, [fname '.log']));
                fprintf('done!\n');
            end
        end
        
        function printRow(this, row, outfile, sep)
            % Prints a table row using a given separator whilst inserting appropriate amounts
            % of tabs
            sl = length(sep);
            for i = 1:length(row)-1
                str = row{i};
                fillstabs = floor((sl*(i~=1)+length(str))/this.TabCharLen);
                tottabs = ceil((sl*(i~=1)+this.contlen(i))/this.TabCharLen);
                fprintf(outfile,'%s%s',[str repmat(char(9),1,tottabs-fillstabs)],sep);
            end
        end
        
        function str = stringify(this, data)
            % Converts any datatype to a string
            
            % Format cell array given
            if iscell(data{end})
                % if format cell is only one item but have more values,
                % apply same format string
                if length(data{end}) == 1 && length(data)-1 > 1
                    data{end} = repmat(data{end},1,length(data)-1);
                    if this.HasRowHeader
                        % Make sure the row header becomes a string if not
                        % already one
                        data(1) = this.stringify(data(1));
                        data{end}{1} = '%s';
                    end
                elseif this.HasRowHeader && length(data{end}) == length(data)-2
                    % Make sure the row header becomes a string if not
                    % already one
                    data(1) = this.stringify(data(1));
                    data{end} = ['%s' data{end}(:)'];
                end
                str = cell(1,length(data)-1);
                for i=1:length(data)-1
                    if isa(data{end}{i},'function_handle')
                        str{i} = data{end}{i}(data{i});
                    else
                        str{i} = sprintf(data{end}{i},data{i});
                    end
                end
            else % convert to strings if no specific format is given
                str = cell(1,length(data));
                for i=1:length(data)
                    el = data{i};
                    if isa(el,'char')
                        str{i} = el;
                    elseif isinteger(el)
                        if numel(el) > 1
                            str{i} = ['[' this.implode(el(:),', ','%d') ']'];
                        else
                            str{i} = sprintf('%d',el);
                        end
                    elseif isnumeric(el)
                        if numel(el) > 1
                            if isvector(el) && length(el) < 100
                                str{i} = ['[' this.implode(el(:),', ','%g') ']'];
                            else
                                str{i} = ['[' this.implode(size(el),'x','%d') ' ' class(el) ']'];
                            end
                        else
                            if isempty(el)
                                str{i} = '[]';
                            else
                                str{i} = sprintf('%g',el);
                            end
                        end
                    elseif isa(el,'function_handle')
                        str{i} = func2str(el);
                    elseif isa(el,'handle')
                        mc = metaclass(el);
                        str{i} = mc.Name;
                    elseif islogical(el)
                        if numel(el) > 1
                            str{i} = this.implode(el(:),', ','%d');
                        else
                            str{i} = sprintf('%d',el);
                        end
                    else
                        error('Cannot automatically convert an argument of type %s for PrintTable display.',class(el));
                    end
                end
            end
        end
        
        function str = implode(~, data, glue, format)
            str = '';
            if ~isempty(data)
                if nargin < 3
                    format = '%2.3e';
                    if nargin < 2
                        glue = ', ';
                    end
                end
                if isa(data,'cell')
                    str = data{1};
                    for idx = 2:length(data)
                        str = [str glue data{idx}];%#ok
                    end
                elseif isnumeric(data)
                    % first n-1 entries
                    if numel(data) > 1
                        str = sprintf([format glue],data(1:end-1));
                    end
                    % append last, no glue afterwards needed
                    str = [str sprintf(format,data(end))];
                else
                    error('Can only pass cell arrays of strings or a vector with sprintf format pattern');
                end
            end
        end
    end
    
    methods(Static)
        function t = test_PrintTable
            % A simple test for PrintTable
            t = PrintTable;
            t.Caption = 'This is my PrintTable test.';
            t.addRow('A','B','C');
            t.addRow('123','456','789');
            t.addRow('1234567','12345','789');
            t.addRow('1234567','123456','789');
            t.addRow('1234567','1234567','789');
            t.addRow('foo','bar',datestr(clock));
            t.addRow(123.45678,pi,789,{'%2.3f','$%4.4g$','decimal: %d'});
            t.addRow('12345678','123','789');
            t.addRow('123456789','123','789');
            t.addRow(123.45678,pi,789,{'%2.3f',@(v)sprintf('functioned pi=%g!',v-3),'decimal: %d'});
            t.addRow('attention: inserting tabs per format','\t','destroys the table tabbing',{'%s','1\t2%s3\t','%s'});
            t.display;
            
            t.Format = 'tex';
            t.print;
            t.HasHeader = true;
            t.print;
            
            tt = t';
            tt.print;
        end
        
        function t = test_PrintTable_RowHeader_Caption
            % A simple test for PrintTable
            t = PrintTable('This is PrintTable RowHeader Caption test, created on %s',datestr(now));
            t.HasRowHeader = true;
            t.HasHeader = true;
            t.addRow('A','B','C');
            t.addRow('header-autofmt',456,789,{'%d'});
            t.addRow(1234.345,456,789,{'%2.2E','%d','%d'});
            t.addRow('header-expl-fmt',456,pi,{'%s','%d','%2.2f'});
            t.addRow('nofmt-header',456,pi,{'%d','%f'});
            t.addRow('1234567','12345','789');
            t.addRow('foo','bar',datestr(clock));
            t.addRow(123.45678,pi,789,{'%2.3f','$%4.4g$','decimal: %d'});
            t.addRow(12345678,'123','789');
            t.addRow(12345.6789,'123','789');
            t.display;
            
            t.Format = 'tex';
            t.print;
            t.HasHeader = true;
            t.print;
            t.saveToFile('test_PrintTable_RowHeader_Caption.pdf');
        end
        
         function t = test_PrintTable_LaTeX_Export
            % A simple test for PrintTable
            t = PrintTable('LaTeX PrintTable demo, %s',datestr(now));
            t.HasRowHeader = true;
            t.HasHeader = true;
            t.addRow('A','B','C');
            t.addRow('Data 1',456,789,{'$%d$'});
            t.addRow(1234.345,456,789,{'$%2.2E$','$%d$','$%d$'});
            t.addRow('header-expl-fmt',456,pi,{'%s','$%d$','$%2.2f$'});
            t.addRow('1234567','12345','789');
            x = 4;
            t.addRow('x=4','\sin(x)',sin(x),{'$%s$','%f'});
            t.addRow('$x=4,\alpha=.2$','\alpha\exp(x)\cos(x)',.2*exp(x)*cos(x),{'$%s$','%f'});
            t.display;
            
            % LaTeX
            t.saveToFile('mytable_tex.tex',true);
            % Tight PDF
            t.saveToFile('mytable_tightpdf.pdf',true);
            % Whole page PDF
            t.TightPDF = false;
            t.saveToFile('mytable_fullpage.pdf',true);
        end
    end
    
end