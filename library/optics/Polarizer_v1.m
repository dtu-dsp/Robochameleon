%> @file Polarizer_v1.m
%> @brief Polarizer model
%>
%> @class Polarizer_v1
%> @brief Polarizer model
%> 
%> @ingroup physModels
%> 
%> Polarizer (TE/TM only, not multimode compatible) with finite extinction 
%> ratio.  If the input is a single-polarization signal, it assigns a
%> polarization.  If the input is dual-pol, it acts like a normal polarizer.
%>
%> The state of polarization can be specified in either Jones or Stokes
%> space
%> 
%> For Stokes operation, we use the same sign convention as: \ref Gordon [1]
%> i.e. right-circular has sy = isx and in that case S3 = 1
%> Normalization is chosen so that right-circular is (0, 0, 1),
%> horizontal (x) is (1, 0, 0), ...
%>
%> __Example__
%> @code
%>   param.polarizer.basis = [1 1i];
%>   param.polarizer.Type = 'Jones';
%>   param.polarizer.ER = 20;
%>   polarizer = Polarizer_v1(param.polarizer);
%>
%>   sigIn = createDummySignal_v1();
%> 
%>   sigOut = polarizer.traverse(sigIn);
%>
%>   pabs(sigIn);
%>   pabs(sigOut);
%> @endcode
%>
%> __References__
%> \anchor Gordon [1] J. P. Gordon 
%> and H. Kogelnik, "PMD fundamentals: Polarization mode dispersion in 
%> optical fibers," Proc. Natl. Acad. Sci., vol. 97, no. 9, pp. 4541�4550, 2000
%>
%> @author Molly Piels
%>
%> @version 1
classdef Polarizer_v1 < unit
    
    properties
        %> state of polarization vector (Jones)
        basis;  
        %> extinction ratio (dB)
        ER = inf;        
        %> Jones or Stokes? {'Jones' | 'Stokes' | 'nDJones'}
        Type;        
        %> Number of input arguments
        nInputs = 1; 
        %> Number of output arguments
        nOutputs = 1; 
    end
    
    methods (Static)
        
        %> @brief Convert Stokes vector to Jones vector
        %>
        %> Convert Stokes vector to Jones vector.  Note there is an
        %> inherent twofold ambiguity in this operation.  This is resolved
        %> by somewhat arbitrarily assigning right-circular to 001
        %>
        %> @param vin Stokes vector to convert
        %>
        %> @retval vout Associated Jones vector
        function vout = stokes2jones(vin)
            %pauli spin matrices
            p=zeros(2,2,3);
            p(:,:,1)=[1, 0; 0, -1];
            p(:,:,2)=[0, 1; 1, 0];
            p(:,:,3)=[0, -1i; 1i, 0];

            %compute dyadic operator of Jones rep.
            for jj=1:3
                p(:,:,jj)=p(:,:,jj)*vin(jj);
            end
            dyad=0.5*(eye(2)+sum(p,3));
            
            %get Ex, Ey, and angle from that
            Ex_m=sqrt(dyad(1,1));
            Ey_m=sqrt(dyad(2,2));
            dphi=angle(dyad(1,2));
            
            %output
            vout=[Ex_m; Ey_m*exp(-1i*dphi)];
            
        end
    end
    
    methods
        
        %> @brief Class constructor
        %>
        %> Jones usage:
        %> basis is a 1x2 or 2x1 complex vector.
        %> Stokes usage:
        %> basis is a 1x4, 4x1, 1x3, or 3x1 real vector
        %> 
        %> @param param.basis State of polarization of output
        %> @param param.Type Specify whether Jones or Stokes
        %> @param param.ER Extinction ratio. [Default: inf]
        %> 
        %> @retval obj Polarizer_v1 object
        function obj = Polarizer_v1(param)
            obj.setparams(param);
            
            %error checking
            switch obj.Type
                case 'Jones'
                    if numel(obj.basis)~=2
                        robolog('Polarization state specification for Jones type polarizers must be a 2x1 or 1x2 vector', 'ERR')
                    end
                case 'Stokes'
                    if numel(obj.basis)==4
                        obj.basis=obj.basis(2:end)/obj.basis(1);
                    elseif numel(obj.basis)~=3
                        robolog('Polarization state specification for Stokes type polarizers must be a 4x1 or 3x1 vector', 'ERR')
                    end
                    if any(imag(obj.basis(:)))
                        robolog('Polarization state specification for Stokes type polarizer must be real', 'ERR')
                    end
                case 'nDJones'
                    %WE DO NOT CARE
                otherwise
                    robolog('Unsupported polarizer type', 'ERR')
            end
        end
        
        
        %>  @brief Traverse function
        %>
        %>  Computes Jones matrix associated with polarizer, then either
        %> uses it or just assigns a polarization based on basis vector
        %>
        %> @param in input signal (can have 1 or two columns)
        %>
        %> @retval out output signal - has two columns
        %> @retval results no results
        function out = traverse(obj,in)
            
            %ER
            ER_lin=10^(-obj.ER/10);
            
            %make sure we're not trying to polarize too many/few modes
%             if in.N > 2
%                 robolog('Polarizer only works with 1 or 2 modes, this input has %d', 'ERR', in{1}.N)
%             end

            %form orthogonal basis from specified SOP
            switch obj.Type
                case 'Jones'
                    vpol=[obj.basis(1) obj.basis(2)];
                    M=[obj.basis(1) -conj(obj.basis(2)); obj.basis(2)  conj(obj.basis(1))];
                case 'Stokes'
                    vpol=obj.stokes2jones(obj.basis);
                    M=[vpol(1) -conj(vpol(2)); vpol(2)  conj(vpol(1))];
                case 'nDJones'
                    vpol = obj.basis(:).';
                    M = zeros(length(vpol), length(vpol));
                    M(1,:) = vpol;
                    
                otherwise
                    robolog('Unsupported polarizer type', 'ERR')
            end
            
            %make Jones matrix representation of polarizer
            [U,~,V]=svd(M);
            diagonal = ER_lin*ones(1, length(vpol));
            diagonal(1) = 1-ER_lin*length(vpol);
            J=(U*V)*diag(diagonal)*(V'*U');

            %output
             if in.N==length(vpol)
                out=in*J;
                %track power
                Pout = out.P;       %done correctly in mtimes
                P_col_frac = pwr.meanpwr(out.get);
                P_col_frac = P_col_frac / sum(P_col_frac);
                for jj = 1:length(P_col_frac)
                    PCol(jj) = P_col_frac(jj)*in.P;
                end
                out = set(out, 'PCol', PCol);
             else
                 if in.N ~= 1
                     robolog('Polarizer input must have same number of modes as basis or only 1 mode', 'ERR');
                 end
                 F_out=repmat(get(in), 1, length(vpol));
                 F_out = F_out*M;
                 P_col_frac = pwr.meanpwr(F_out);
                 P_col_frac = P_col_frac / sum(P_col_frac);
                 for jj = 1:length(P_col_frac)
                     PCol(jj) = P_col_frac(jj)*in.P;
                 end
                 out = signal_interface(F_out, struct('Fs',in.Fs,'Rs',in.Rs, 'PCol', PCol, 'Fc', in.Fc));
             end
        end 
    end
end
