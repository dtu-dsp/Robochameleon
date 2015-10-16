%> @defgroup base Basic Classes
%> @brief Core Robochameleon classes
%> 
%> Standard representations for functions, signals, and physical constants.
%> To add a class to this group, add the line: \code @ingroup base
%> \endcode to the comment header.
%>
%>
%>
%> @defgroup coreDSP Core DSP
%> @brief Stable, standard, DSP blocks
%> 
%> DSP blocks which are both stable (working in most cases) and also standard 
%> (meant for use as a benchmark, in non-DSP-related experiments, etc.).
%> 
%> To add a class to this group, add the line: \code @ingroup coreDSP
%> \endcode to the comment header.
%>
%>
%>
%> @weakgroup stableDSP Stable DSP
%> @brief Stable DSP blocks that may not be "standard"
%> 
%> DSP blocks that are stable (working in most cases), but not always used.
%> These are blocks that are potentially useful to advanced users, but not
%> appropriate for someone learning how to do DSP.
%> 
%> To add a class to this group, add the line: \code @ingroup stableDSP
%> \endcode to the comment header.
%>
%>
%>
%> @defgroup physModels Physical models
%> @brief Models of system components
%> 
%> Any kind of physical model of the channel, receiver, or transmitter
%> components.
%> 
%> To add a class to this group, add the line: \code @ingroup physModels
%> \endcode to the comment header.
%>
%>
%>
%> @defgroup roboUtils Robochameleon utilities
%> @brief Robochameleon-specific utilities
%> 
%> Helper functions that are somewhat unique to Robochameleon (e.g. dB2lin
%> is a utility, but not a robochameleon utility, because it's very general).
%> 
%> To add a class to this group, add the line: \code @ingroup roboUtils
%> \endcode to the comment header.

