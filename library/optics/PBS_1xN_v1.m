%> @file PBS_1xN_v1.m
%> @brief implementation of a polarizing beam splitter
%>
%> @class PBS_1xN_v1
%> @brief Polarizing beam splitter
%>
%> @ingroup physModels
%> 
%> This block takes a single input and splits it into an arbitrary number 
%> of outputs (N), according to the set of specified state of polarization
%> vectors.  The input should be single-mode (with two orthogonal 
%> polarizations).  
%> 
%> __Observations:__
%>
%> Fundamentally, the only kind of PBS that can be lossless is one that
%> splits a signal into two orthogonal polarizations.  This particular
%> implementation allows the user to specify non-orthogonal polarizations,
%> and if this is done, it will NOT calculate the loss associated with that
%> choice.  This is because we expect that loss to be somewhat
%> implementation-specific.
%>
%> __Example:__
%> @code
%> pb = PBS_Nx1_v1(struct('nOutputs', 2, 'bases', [1 0; 0 1]);
%> @endcode
%> This will construct a standard (TE/TM) PBS.
%>
%> @see Polarizer_v1
%> @see PBC_Nx1_v1
%> @see BS_1xN_v1
%>
%> @author Molly Piels 
classdef PBS_1xN_v1 < unit
    
    properties
        %> Matrix of input SOPs, specified in Jones space.  Should be properly normalized.
        bases;  
        %> (optional) input state of polarization (Jones).  Allows user to pass input signal through a polarizer before the PBS.  This is useful for the local oscillator in a coherent receiver, for example.
        align_in;     
        %> Extinction ratio (dB)
        ER;           
        
        %> Number of input arguments
        nInputs = 1; 
        %> Number of output arguments
        nOutputs; 
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
            polarizer = Polarizer_v1(struct('basis',v, 'Type', 'nDJones', 'ER', ER));
            Eout = traverse(polarizer, Ein);
        end

    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> @param param.nOutputs number of outputs
        %> @param param.bases set of bases in Jones space - single matrix
        %> @param param.ER extinction ratio (dB)
        %> @param param.align_in optional alignment for input polarizer (Jones vector)
        %> @retval obj object of type PBS_Nx1_v1
        function obj = PBS_1xN_v1(param)
            %Intialize parameters
            obj.nOutputs=param.nOutputs;
            dim=find(size(param.bases)==obj.nInputs);
            if dim==1
                obj.bases=param.bases;
            else
                obj.bases=rot90(param.bases);
            end

            if isfield(param, 'align_in')
                if size(param.align_in,2)>size(param.align_in,1)
                    obj.align_in=param.align_in;
                end
            else
                obj.align_in=inf;
            end
            if isfield(param, 'ER')
                obj.ER = param.ER;            
            else
                obj.ER=inf;
            end
            
            
        end
        
        
        %> @brief Main function
        %>
        %> Each output is the input passed through the relevant polarizer.
        function varargout = traverse(obj,in)
             
            varargout = cell(1, obj.nOutputs);
            
            %deal with single-polarization case (optional input polarizer)
            if ~isinf(obj.align_in)
                in=obj.orient_sig(in, obj.align_in, obj.ER);
            end
            
            %outputs
            for jj=1:obj.nOutputs
                varargout{jj}=obj.orient_sig(in, obj.bases(:,jj), obj.ER);
            end


            % results is a structure containing all important "results"
            % e.g. everything that is of importance for monitoring,
            % plotting, etc.
            %obj.results = struct('power', pwr(10*log10(Ps/Pn),  {Ps, 'mW'}));
            
        end
        
    end
    
end