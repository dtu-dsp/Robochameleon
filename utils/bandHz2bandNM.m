%> @file bandHz2bandNM.m
%> @brief Converts band from Hz to nm
%>
%> @ingroup utils
%>
%> @author Simone Gaiarin
%>
%> @version 1

%>@brief Converts band from Hz to nm
%>
%> @param bandHz Bandwidth [Hz]
%> @param varargin{1} Carrier wavelength [nm] (Optional) Default:1550
%>
%> @retval bandNM Bandwidth [nm]
function [ bandNM ] = bandHz2bandNM( bandHz, varargin )
wavelength = 1550;
if ~isempty(varargin)
    wavelength = varargin{1};
end
c = const.c;
bandNM = c/(c/(wavelength*1e-9) - bandHz/2) - c/(c/(wavelength*1e-9) + bandHz/2);
bandNM = bandNM*1e9;
end
