%> @file bandNM2bandHz.m
%> @brief Converts band from nm to Hz
%>
%> @ingroup utils
%>
%> @author Simone Gaiarin
%>
%> @version 1

%>@brief Converts band from nm to Hz
%>
%> @param bandNM Bandwidth [nm]
%> @param varargin{1} Carrier wavelength [nm] (Optional) Default:1550
%>
%> @retval bandHz Bandwidth [Hz]
function [ bandHz ] = bandNM2bandHz( bandNM, varargin )
wavelength = 1550;
if ~isempty(varargin)
    wavelength = varargin{1};
end
c = const.c;
bandHz = c/((wavelength*1e-9) - (bandNM*1e-9)/2) - c/((wavelength*1e-9) + (bandNM*1e-9)/2);
end
