%> @file DocumentationGeneration.m
%> @brief [Documentation generation] (@ref docgen)
%> 
%> \page docgen Documentation generation
%> @brief How to write and compile documentation using Doxygen
%> 
%> \section Overview Overview
%> Robochameleon uses Doxygen to automatically generate API documentation.
%> Doxygen integration into Matlab is accomplished using Fabrice's perl scripts,
%> which are saved in the \\doc\\scripts folder.  The Matlab Central project
%> page is  <a href="http://www.mathworks.com/matlabcentral/fileexchange/25925-using-doxygen-with-matlab">here</a>.
%>
%> In order to compile correctly, there are certain syntax rules the
%> comments must obey.  The basics are:  
%> 1. Comment lines should start with @code %> @endcode rather than @code % @endcode
%> 2. Comments go immediately above what they refer to, with no whitespace
%> in between.
%> 3. Tags with @code @ @endcode are used to identify common fields, like
%> brief description, author, version, ...
%> 4. White space matters
%>
%> There is an example of a fully documented class below, and also some examples
%> on the Matlab Central project page for the perl scripts.
%>
%> For advanced formatting, see <a href="https://www.stack.nl/~dimitri/doxygen/manual/index.html"> the
%> Doxygen manual </a>
%> 
%> \tableofcontents
%>
%> 
%> \section Writing Documenting the code
%> The best way to start writing a unit is to use ClassTemplate_v1 as a
%> template.  You can see how doxygen displays the following code by 
%> clicking the above link, and the source code by opening it in matlab.
%> The rest of this section goes through the comment structure and explains
%> what the parts do.
%>
%> The following three commands are used to add the unit to the list of files,
%> classes, and module members, respectively.  The text following the 
%> "brief" tag is the text that is put in the tables on those pages.
%> @code
%> %> @file ClassTemplate_v1.m
%> %> @brief A short description of the class
%> %>
%> %> @class ClassTemplate_v1
%> %> @brief A short description of the class
%> %>
%> %> @ingroup {base|stableDSP|physModels|roboUtils|coreDSP}
%> @endcode
%> 
%>
%> After the header comes the main description of the class, which will appear at
%> the top of the the class reference page.  Markdown syntax is used to 
%> create section headings and lists.  
%> @code
%> %> A longer description of the class, with all the details required which spans multiple lines
%> %> A longer description of the class, with all the details required which spans multiple lines
%> %> A longer description of the class, with all the details required which spans multiple lines
%> %>
%> %>
%> %> __Observations:__
%> %>
%> %> 1. First observation
%> %>
%> %> 2. Second observation
%> %>
%> %>
%> %> __Conventions:__
%> %> * First convention
%> %> * Second convention
%> %>
%> %>
%> %> __Example:__
%> %> @code
%> %>   % Here we put a FULLY WORKING example
%> %>   param.classtemp.param1      = 2;
%> %>   param.classtemp.param2      = 'test';
%> %>   param.classtemp.param3      = false;
%> %>
%> %>   clTemp = ClassTemplate_v1(param.classtemp);
%> %>
%> %>   param.sig.L = 10e6;
%> %>   param.sig.Fs = 64e9;
%> %>   param.sig.Fc = 193.1e12;
%> %>   param.sig.Rs = 10e9;
%> %>   param.sig.PCol = [pwr(20,{-2,'dBm'}), pwr(-inf,{-inf,'dBm'})];
%> %>   Ein = rand(1000,2);
%> %>   sIn = signal_interface(Ein, param.sig);
%> %>
%> %>   sigOut = clTemp.traverse(sigIn);
%> %> @ endcode
%> %>
%> %>
%> %> __References:__
%> %>
%> %> * [1] First formatted reference
%> %> * [2] Second formatted reference
%> %>
%> %> @author Author 1
%> %> @author Author 2
%> %>
%> %> @version 1
%> @endcode
%>
%> The class definition goes immediately after the comment header, with no
%> white space in between.  Class property definitions should be commented
%> above where they are defined.  This is not the most useful place to put
%> notes about default values, as this information is displayed in table
%> format.  This information should go in the constructor documentation.  
%> Multi-line (word wrapped) expressions will not appear (at all) in the
%> documentation.
%> 
%> @code
%> classdef ClassTemplate_v1 < unit
%> 
%>     properties        
%>         %> Description of param1 [measurment unit]. (Don't say anything about default values, they go in the constructor)
%>         param1 = 5
%>         %> Description of param2 [measurment unit].       
%>         param2
%>         %> Description of param3 which is a flag that can take values true or false
%>         param3Enabled
%>         %> Number of inputs
%>         nInputs = 1;
%>         %> Number of outputs
%>         nOutputs = 1;        
%>     end
%>     
%> @endcode
%> 
%> Each member function (method) should have its own documentation.  The
%> constructor is where information about default property values should
%> go.  The syntax/format for method documentation is similar to the syntax
%> for the class.  The tags param and retval can be used to label input
%> parameters and returned values - these will be displayed in tables.
%> 
%> @code
%>     methods (Static)
%>         
%>     end
%>     
%>     methods
%> 
%>         %> @brief Class constructor
%>         %>
%>         %> Constructs an object of type ClassTemplate_v1 and more information..
%>         %> Don't put example here, since we have it in the description..
%>         %>        
%>         %> @param param.param1          Param1 description (capital first letter) [unit]. [Default: Value]
%>         %> @param param.param2          Param2 description (capital first letter) [unit].
%>         %> @param param.param3Enabled   Description of a flag to enable or disable something. [Default: Value]
%>         %> 
%>         %> @retval obj      An instance of the class ClassTemplate_v1
%>         function obj = ClassTemplate_v1(param)                                       
%>             % Automatically assign params to matching properties
%>             % All the parameters without a default value specified in the property definition
%>             % should be put in requiredParams
%>             requiredParams = {'param2'};
%>             obj.setparams(param, requiredParams);                
%>         end
%>         
%>         %> @brief Brief description of what the traverse function does
%>         %>
%>         %> @param in    The signal_interface of the input signal that...
%>         %> 
%>         %> @retval out  The signal_interface of the signal which has been...
%>         function out = traverse(obj, in)
%>             
%>         end
%>     end
%> end
%> @endcode
%> 
%> \section Updating Updating the documentation
%>
%> \subsection installing Setting up Doxygen for Matlab
%> Running Doxygen requires Doxygen software as well as Perl.  There are
%> installation instructions <a
%> href="http://www.mathworks.com/matlabcentral/fileexchange/25925-using-doxygen-with-matlab">here</a>,
%> but we will reproduce them in case the link goes dead:
%> 
%>   1. You need to have the Doxygen software installed (version 1.5.9 or newer required (tested with version 1.7.1)) 
%>   2. You need to have perl installed (perl is shipped with Matlab, located usually in $matlabroot\sys\perl\win32\bin) 
%>
%> Note for Windows users : 
%> In certain circumstances, the association between .pl files and the perl executable is not well configured, leading to "Argument must contain filename -1 at C:\DoxygenMatlab\m2cpp.pl line 4" when running doxygen. To work around this issue, you should execute the following lines in a Windows command prompt ("cmd") :
%>
%>  @code 
%> assoc .pl=PerlScript 
%>   ftype PerlScript=C:\Program Files\MATLAB\R2010b\sys\perl\win32\bin\perl.exe %1 %* 
%> @endcode
%>(don't forget to replace the path to the perl.exe file with yours in the line above)
%>
%> We have been running Doxygen on Windows through a linux emulator, <a
%> href="https://www.cygwin.com/">Cygwin</a>, with no issues.  Installation
%> instructions in this case are the same - install perl (all perl modules)
%> and Doxygen using the Cygwin installer.
%>
%> \subsection Compiling Compiling
%> To update the Doxygen documentation run the following command from the _doc_ folder:
%>
%>  @code  doxygen Doxyfile @endcode
%>
%> then, to generate the PDF manual (refman.pdf), execute the following command from the folder _doc/user manual/latex_:
%>
%>   @code make @endcode
%> 
%> We have not gotten the PDF to compile successfully.
%>
%> One line command to regenerate the documentation under Linux and MAC (pdflatex and a latex distribution are required). In folder _doc/scripts_ execute:
%>
%>     @code  chmod +x * && ./update_documentation.sh @endcode
%> 
%> **WARNING** The Doxygen configuration files uses relative path to find the source code and the necessary scripts. So if
%> you move or rename the _doc_ and _scripts_ folders or the _Doxyfile_ file and the scripts the documentation may not be generated correctly.
%>
%> **WARNING** Before updating the documentation edit the parameter _STRIP_FROM_PATH_ in the file _Doxyfile_ from the _doc_ folder
%> by inserting the absolute path of the robochameleon root folder.
%>
%> **WARNING** All the files in the folders _base_, _devel_, _library_, _utils_ are documented, also the ones not tracked by git. Before
%> updating the documentation it's better to temporary clone a vanilla version of the repository in a new directory and update the documentation
%> from there so that there won't be any spurious files.