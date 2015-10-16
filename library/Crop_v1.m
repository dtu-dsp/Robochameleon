%> @file Crop_v1.m
%> @brief Contains the implementation of a signal cropping utility.
%>
%> @class Crop_v1
%> @brief Crops a signal with many samples to fewer samples 
%>
%>
%> Example:
%> @code
%> Crop_v1 = Crop_v1(struct('Margin', [0.1 0.1]));
%> @endcode
%> This will cut 10% of the signal from both ends.
%>
%>
%> @author Molly Piels
%> @version 1
classdef Crop_v1 < unit

    properties
        nInputs = 1;
        nOutputs = 1;
        
        %> Amount of signal to crop.  Either specified as a percentage (0 to
        %> 1) or sample index.\n  If the margin is a 1x2 vector, it is the
        %> distance to remove from the ends (i.e. [0.1, 0.1] will chop 10%
        %> from both ends).\n If the margin is a scalar, that fraction or 
        %> number of samples is taken from the center of the signal.
        Margin=nan;    
        %> Amount of signal to keep.  Either specified as a percentage (0 to
        %> 1) or sample index.\n  If the margin is a 1x2 vector, it is the
        %> distance to keep, counting from the beginning (i.e. [0.1, 0.1] 
        %> will chop return a 0-length vector, [0.1, 0.9] will do the same
        %> thing as param.Margin=[0.1 0.1];\n If the margin is a scalar, 
        %> that fraction or number of samples is taken from the center of 
        %> the signal.
        InverseMargin=nan;
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> Either Margin or InverseMargin must be specified.  By default,
        %> one input/output is assumed, though this can also be changed by
        %> setting nInputs or nOutputs.
        %>
        %> @param param.Margin maps to obj.margin
        %> @param param.InverseMargin maps to obj.InverseMargin
        %>
        %> @return instance of the Crop_v1 class
        function obj = Crop_v1(param)
            %make sure numbers of inputs and outputs match
            if isfield(param, 'nInputs')
                if isfield(param, 'nOutputs')
                    if param.nOutputs ~= param.nInputs
                        robolog('Number of outputs must be equal to the number of inputs', 'ERR');
                    end
                else
                    param.nOutputs=param.nInputs;
                end
            elseif isfield(param, 'nOutputs')
                    param.nInputs=param.nOutputs;
            end
            
            setparams(obj, param);
            
            if isnan(obj.Margin)&&isnan(obj.InverseMargin)
                robolog('Either Margin or InverseMargin must be specified', 'ERR');
            end
            
        end
        
        %> @brief Main function
        %>
        %> Crops the signal
        %>
        %> @param varargin input signal(s)
        %>
        %> @return varargout cropped signal(s)
        function varargout = traverse(obj,varargin)
            varargout = cell(obj.nOutputs,1);
            for i=1:obj.nOutputs
                if isnan(obj.Margin)
                    varargout{i} = fun1(varargin{i}, @(x)obj.InvSkipMargin(obj.InverseMargin, x));
                else
                    varargout{i} = fun1(varargin{i}, @(x)obj.skipMargin(obj.Margin, x));
                end
            end
        end
    end
        
    methods (Static)
        %> @brief   Skips symbols at beginning and/or end
        %>
        %> Skips symbols at beginning and/or end of sequence
        %>
        %> @param margin  how much of sequence to skip (fraction between 0
        %>  and 1 or number of samples)
        %> @param in input data
        function out = skipMargin(margin, in)
            % If specified as percentage, convert to symbols
            if sum(margin) < 1
                skip = margin*length(in);
            else
                skip = margin;
            end
            if isscalar(skip)
                % Half and half
                skip = [skip/2 length(in)-skip/2];
            else
                % Up to this symbol
                skip(2) = length(in) - skip(2);
            end
            % If no margin...
            if skip(1) == 0
                skip(1) = 1;
            end
            if skip(2) > length(in)
                skip(2) = length(in);
            end
            % Trim
            out = in(round(skip(1)):round(skip(2)));
            out = out(:);
        end        
        
        %> @brief   Skips symbols at beginning and/or end
        %>
        %> Skips symbols at beginning and/or end of sequence.  Unlike
        %> Crop_v1::skipMargin, the user specifies which samples to keep, not
        %> which to throw out.
        %>
        %> @param margin  how much of sequence to keep (fraction between 0
        %>  and 1 or number of samples)
        %> @param in input data
        function out = InvSkipMargin(margin, in)
            % If specified as percentage, convert to symbols
            if sum(margin) < 2
                skip = margin*length(in);
            else
                skip = margin;
            end
            if isscalar(skip)
                % Half and half
                skip = [skip/2 length(in)-skip/2];
            end
            % If no margin...
            if skip(1) == 0
                skip(1) = 1;
            end
            if skip(2) > length(in)
                skip(2) = length(in);
            end
            % Trim
            out = in(round(skip(1)):round(skip(2)));
            out = out(:);
        end        
    end
    
end