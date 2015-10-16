%> @file Polarizer_v1.m
%> @brief polarizer model
%>
%> @class Polarizer_v1
%> @brief polarizer model
%> 
%>  @ingroup physModels
%> 
%> Polarizer (TE/TM only, not multimode compatible) with finite extinction 
%> ratio.  If the input is a single-polarization signal, it assigns a
%> polarization.  If the input is dual-pol, it acts like a normal polarizer.
%>
%> The state of polarization can be specified in either Jones or Stokes
%> space
%> 
%> For Stokes operation, we use the same sign convention as: J. P. Gordon 
%> and H. Kogelnik, "PMD fundamentals: Polarization mode dispersion in 
%> optical fibers," Proc. Natl. Acad. Sci., vol. 97, no. 9, pp. 4541�4550, 
%> 2000.
%> i.e. right-circular has sy = isx and in that case S3 = 1
%> Normalization is chosen so that right-circular is (0, 0, 1),
%> horizontal (x) is (1, 0, 0), ...
%
%> @author Molly Piels
%> @version 1
classdef Polarizer_v1 < unit
    
    properties
        %> state of polarization vector (Jones)
        basis;  
        %> extinction ratio (dB)
        ER;        
        %> Jones or Stokes? {'Jones' | 'Stokes'}
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
        %> Class constructor
        %> Example:
        %> @code
        %> polarizer = Polarizer_v1(struct('basis',[1 1i], 'Type', 'Jones', 'ER', 20));
        %> @endcode
        %> Jones usage:
        %> basis is a 1x2 or 2x1 complex vector.
        %> Stokes usage:
        %> basis is a 1x4, 4x1, 1x3, or 3x1 real vector
        %> 
        %> @param param.basis state of polarization of output
        %> @param param.Type specify whether Jones or Stokes
        %> @param param.ER extinction ratio
        %> 
        %> @retval obj Polarizer_v1 object
        function obj = Polarizer_v1(param)
            %Intialize parameters
            obj.basis=param.basis;
            obj.Type=param.Type;
            if isfield(param, 'ER')
                obj.ER = param.ER;            
            else
                obj.ER=inf;
            end
            
            %error checking
            switch obj.Type
                case 'Jones'
                    if numel(obj.basis)~=2
                        error('Polarization state specification for Jones type polarizers must be a 2x1 or 1x2 vector')
                    end
                case 'Stokes'
                    if numel(obj.basis)==4
                        obj.basis=obj.basis(2:end)/obj.basis(1);
                    elseif numel(obj.basis)~=3
                        error('Polarization state specification for Stokes type polarizers must be a 4x1 or 3x1 vector')
                    end
                    if any(imag(obj.basis(:)))
                        error('Polarization state specification for Stokes type polarizer must be real')
                    end
                otherwise
                    error('Unsupported polarizer type')
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
            if in.N > 2
                error('Polarizer only works with 1 or 2 modes, this input has %d', in{1}.N)
            end

            %form orthogonal basis from specified SOP
            switch obj.Type
                case 'Jones'
                    vpol=[obj.basis(1) obj.basis(2)];
                    M=[obj.basis(1) -conj(obj.basis(2)); obj.basis(2)  conj(obj.basis(1))];
                case 'Stokes'
                    vpol=obj.stokes2jones(obj.basis);
                    M=[vpol(1) -conj(vpol(2)); vpol(2)  conj(vpol(1))];
                otherwise
                    error('Unsupported polarizer type')
            end
            
            %make Jones matrix representation of polarizer
            [U,~,V]=svd(M);
            J=(U*V)*[1-ER_lin 0; 0 ER_lin]*(V'*U');

            %output
            if in.N==2
                out=in*J;
                %track power
                Pout = out.P;       %done correctly in mtimes
                Pboth = pwr.meanpwr(out.E);
                P1 = Pboth(1)/sum(Pboth);
                P2 = Pboth(2)/sum(Pboth);
                Pcol = [P1*Pout, P2*Pout];
                out = set(out, 'PCol', Pcol);
            else
                F_out=kron(get(in), [vpol(1) vpol(2)]);
                Ptot1 = in.P.Ptot + 20*log10(vpol(1));
                Ptot2 = in.P.Ptot + 20*log10(vpol(2));
                out = signal_interface(F_out, struct('Fs',in.Fs,'Rs',in.Rs, 'PCol', [pwr(in.P.SNR, Ptot1), pwr(in.P.SNR, Ptot2)], 'Fc', in.Fc));
            end
            
        end
        
    end
    
end