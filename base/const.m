%> @file const.m
%> @brief Global variable holding physical constants
%>
%> @class const
%> @brief Global variable holding physical constants
%> 
%> @ingroup base
%>
%> Storage class for physical constant definition.  All constants are in SI
%> units.
%>
%> Example:
%> @code
%> frequency = const.c/wavelength;
%> photon_energy = 2*pi*frequency*const.h;
%> @endcode
%>
%> @author Robert Borkowski
%> @version 1
classdef const
    properties (Constant)
        %> Boltzmann constant (J/K)
        kB = 1.3806488e-23;  
        %> Elementary charge (C)
        q = 1.602176565e-19; 
        %> Planck constant (J*s)
        h = 6.62606957e-34;  
        %> Speed of light in vacuum (m/s)
        c = 299792458;       
    end
end