%> @file PBC_Nx1_v1.m
%> @brief implementation of a polarizing beam combiner
%>
%> @class PBC_Nx1_v1
%> @brief Polarizing beam combiner
%>
%> @ingroup physModels
%> 
%> This block takes an arbitrary number of inputs (N), polarizes each one according 
%> to a set basis vector (specified as a property), and combines them into one 
%> output signal (with two orthogonal polarizations).
%> 
%>__Observations:__
%>
%> Fundamentally, the only kind of PBC that can be lossless is one that
%> combines two orthogonal polarizations.  This particular
%> implementation allows the user to specify non-orthogonal polarizations,
%> and if this is done, it will NOT calculate the loss associated with that
%> choice.  This is because we expect that loss to be somewhat
%> implementation-specific.
%>
%> __Example:__
%> @code
%> pb = PBC_Nx1_v1(struct('nInputs', 3, 'bases', [1 0; sqrt(2) sqrt(2); 0 1]);
%> @endcode
%> This will construct a 3x1 polarizing beam combiner where input 1 is
%> X-polarized, intput 2 is 45 degrees polarized, and input 3 is Y polarized.
%>   
%> @see Polarizer_v1
%> @see PBC_Nx1_v1
%> @see BS_1xN_v1
%>
%> @author Molly Piels 
classdef PBC_Nx1_v1 < unit
    
    properties
        %> matrix of output SOPs, specified in Jones space.  Should be properly normalized.
        bases;
        %> extinction ratio (dB)
        ER;
        
        %> Number of input arguments
        nInputs;
        %> Number of output arguments
        nOutputs = 1;
    end
    
    methods (Static)
    
        %> @brief Orient signal polarization
        %>
        %> If the input signal is unpolarized (waveform has one column only), this will
        %> assign it a polarization.  Otherwise, it will behave as a polarizer - there may
        %> be power loss in this second case.
        %>
        %> @param Ein input (signal_interface object)
        %> @param v output state of polarization (in Jones space)
        %> @param ER extinction ratio (dB)
        %> @retval Eout output (signal_interface object)
        function Eout=orient_sig(Ein, v, ER)
            polarizer = Polarizer_v1(struct('basis',v, 'Type', 'Jones', 'ER', ER));
            Eout = traverse(polarizer, Ein);
        end
        
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> @param param.nInputs number of inputs
        %> @param param.bases set of bases in Jones space - single matrix
        %> @param param.ER extinction ratio (dB)
        %> @retval obj object of type PBC_Nx1_v1
        function obj = PBC_Nx1_v1(param)
            %Intialize parameters
            obj.nInputs=param.nInputs;
            dim=find(size(param.bases)==obj.nInputs);
            if dim==1
                obj.bases=param.bases;
            else
                obj.bases=rot90(param.bases);
            end

            if isfield(param, 'ER')
                obj.ER = param.ER;            
            else
                obj.ER=inf;
            end
                        
        end
                
        %> @brief Main function
        %>
        %> Orients each input, then adds them coherently.
        function out = traverse(obj, varargin)
                       
            out=obj.orient_sig(varargin{1}, obj.bases(1,:), obj.ER);
            for jj=2:obj.nInputs
                out = out+obj.orient_sig(varargin{jj}, obj.bases(jj,:), obj.ER);
            end

            % results is a structure containing all important "results"
            % e.g. everything that is of importance for monitoring,
            % plotting, etc.
            obj.results = struct('power', out.P);
            
        end
        
    end
    
end