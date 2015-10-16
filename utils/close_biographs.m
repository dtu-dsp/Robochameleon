%> @file close_biographs.m   
%> @brief Closes all open biographs.
%> 
%> @ingroup roboUtils
%> 
%> Biographs are generated during module construction and not affected by
%> close all.  @code close_biographs()  @endcode acts like close
%> all for biographs.
%> 
%> Identify biographs by a tag
function close_biographs()

handles = allchild(0);
biographs = strcmp('BioGraphTool',get(handles,'Tag'));
close(handles(biographs));
