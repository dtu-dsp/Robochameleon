classdef Splitter_v1 < unit
%> @file Splitter_v1.m
%> @brief Contains the implementation of a signal splitter utility.
%>
%> @class Splitter_v1
%> @brief Splits a signal with several columns into several signals. 
%>
%> The type of splitter is decided automatically. If the number of output
%> signals is equal to the number of components of the input signal then
%> splits each column into one signal. If the number of output signals is
%> double the number of components of the input signal then i-th component
%> is split into real part to output i and imaginary part to output i+N,
%> where N is the number of input signal components.
%>
%> Example:
%> @code
%> splitter = Splitter_v1(2);
%> @endcode
%>
%> @see Combiner_v1
%>
%> @author Robert Borkowski
%> @version 1
%> @date 11.12.2014

    properties
        nInputs = 1;
        nOutputs;
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> @return instance of the Splitter_v1 class
        function obj = Splitter_v1(nOutputs)
            obj.nOutputs = nOutputs;
        end
        
        function varargout = traverse(obj,in)
            varargout = cell(obj.nOutputs,1);
            if in.N==obj.nOutputs % Complex mode -- each complex signal == one output
                for i=1:obj.nOutputs
                    varargout{i} = in.set(in.E(:,i));
                end
            elseif 2*in.N==obj.nOutputs % Real mode -- each column i divided into real part in output i and imaginary part in column i+N
                for i=1:obj.nOutputs
                    varargout{i} = in.set(real(in.E(:,i)));
                    varargout{i+in.N} = in.set(imag(in.E(:,i)));
                end
            else
                error('Incorrect number of outputs for the signal at the input');
            end
        end
        
    end
    
end