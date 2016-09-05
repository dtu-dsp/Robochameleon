%> @file findUnit.m
%> @brief Finds a unit within a module
%>
%> @ingroup roboUtils
%>
%> __Example:__
%> Set up a simulation for 16 QAM over a linear channel, find the BERT
%> within the setup, and read the BER:
%> @code
%> %MAIN CONTROLS
%> M = 16;     %modulation order
%> Rs = 28e9;  %symbol rate
%> L = 2^16;   %sequence length
%> % PULSE PATTERN GENERATOR
%> param.ppg = struct('order', 15, 'total_length', L, 'Rs', Rs, 'nOutputs', log2(M)/2, 'negatedChannels', 2, 'levels', [-1 1]);
%> ...
%> coherentLink = setup_16QAMLinChannel(param);
%> BERT = findUnit(coherentLink,'BERT_v1');
%> traverse(coherentLink)
%> BER = BERT.results.ber;
%> @endcode
%>

%> @brief Finds a unit within a module
%>
%> Recursively searches and returns the first found unit or module with a given label
%>
%> @param module   module inside of which to look
%> @param label    label name (the same as class name, if not changed)
%>
%> @retval obj found module
%>
%> @author Robert Borkowski
%> @date 2015
function obj = findUnit(module, label)

if ~isa(module,'module')
    error('First input must be of class module.');
end

obj = [];
L = length(label);
for i=1:numel(module.internalUnits)
    o = module.internalUnits{i};
    if strcmp(label,o.label(1:min(L,end)))
        obj = o;
        return;
    elseif isa(o,'module')
        obj = findUnit(o, label);
        if ~isempty(obj), return; end
    end
end