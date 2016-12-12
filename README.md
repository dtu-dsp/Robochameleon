Robochameleon
=============
Robochameleon is a coding framework and component library for simulation and experimental analysis of optical communication systems.  
The framework was designed to facilitate sharing code between researchers by articulating some standard methods and syntax for signal representation and function calls.
It has been used successfully for this purpose within the DSP group at DTU for the past year, and we welcome contributions from other groups.
The library includes physical models of most components found in coherent and incoherent optical communication systems, as well as standard DSP blocks.  
The DSP blocks have been developed over a longer period of time and validated on real data.  

That said, this software is provided "as-is" without warranty of any kind, as stated in the license.

Documentation
=============

There is a quick start guide in powerpoint format in the _doc_ folder.  An HTML version of this file can be found [here](@ref quickstart) 
(link only works from the html API documentation).

To consult the documentation open:

* **<a href="index.html">index.html</a>** located in the folder _doc/user manual/html/_ 

or type `robohelp` in the MATLAB command line.


Examples
=============
Several examples can be found in the _setups/_Demo_ folder

Authors
=======

- Robert Borkowski \<robert.borkow+robochameleon@gmail.com\>
- Edson Porto Da Silva \<edpod@fotonik.dtu.dk\>
- Simone Gaiarin \<simga@fotonik.dtu.dk\>
- Miguel Iglesias \<miguelio@kth.se\>
- Molly Piels \<mopi@fotonik.dtu.dk\>
- Darko Zibar \<dazi@fotoni.dtu.dk\>
- Rasmus Jones \<rajo@fotoni.dtu.dk\>
- Julio Cesar Medeiros Diniz \<jcmdi@fotonik.dtu.dk\>

External collaborators
======================

- Xiaodan Pang \<xiaodan.pang@acreo.se\>
- Oskars Ozolins \<oskars.ozolins@acreo.se\>
- Leonardo Marcon \<leonardo.marcon.1@phd.unipd.it\>

License
=======
Gnu public license version 3

Add-ins
------------
There are several open-source projects that have been incorporated into Robochameleon:

| Name | License | Usage | Source |
|--------|----------|--------|--------|
| ssprop-3.0.1 | GPL v2 | Nonlinear channel model | Photonics Research Lab, Univ. of Maryland <a href="http://www.photonics.umd.edu/software/ssprop/">link</a>|
| scatplot | "copy-left" | Constellation plotting | Alejandro Sanchez-Barba <a href="http://www.mathworks.com/matlabcentral/fileexchange/8577-scatplot">link</a>|
| PrintTable | BSD | Table formatting in BERT readout | Daniel Wirtz <a href="http://www.mathworks.com/matlabcentral/fileexchange/33815-printing-a-formatted-table">link</a>|
| InterPointDistanceMatrix | BSD | Calculate set of Euclidean distances | John D'Errico <a href="http://www.mathworks.com/matlabcentral/fileexchange/18937-ipdm--inter-point-distance-matrix">link</a>|
| ENC8B10B | ? | 8b/10b encoder | Alex Forencich <a href="http://www.alexforencich.com/wiki/en/scripts/matlab/enc8b10b">link</a>|
| cprintf | BSD | text formatting for robolog | Yair Altman <a href="http://www.mathworks.com/matlabcentral/fileexchange/24093-cprintf-display-formatted-colored-text-in-the-command-window">link</a>|
| scripts | Using Doxygen with Matlab| Documentation generation | Fabrice <a href="http://www.mathworks.com/matlabcentral/fileexchange/25925-using-doxygen-with-matlab">link</a>|
| clearex |  | clear all except | Arnaud Laurent|
| cloudPlot | The MathWorks| Constellation display | Daniel Armyr <a href="https://se.mathworks.com/matlabcentral/fileexchange/23238-cloudplot">link</a>|
| convo_bench ver 2.0 | own| Fast convolution using fft | Ilias Konsoulas <a href="https://se.mathworks.com/matlabcentral/fileexchange/44466-beating-matlab-s-convolution-function-conv-m-for-long-real-sequences-">link</a>|
| distinguishable_colors | own| plotting | Tim Holy <a href="https://se.mathworks.com/matlabcentral/fileexchange/29702-generate-maximally-perceptually-distinct-colors">link</a>|
| fieldnamesr | BSD | parameter parsing | Adam Tudor Jones <a href="https://se.mathworks.com/matlabcentral/fileexchange/33262-get-structure-field-names-in-recursive-manner/content/fieldnamesr.m">link</a>|



All but the documentation add-in can be found in the _addons/Name_ folders (as appropriate).  The documentation generation code is in _doc/scripts_.

References
=============

- [Github page] (https://github.com/dtu-dsp/Robochameleon)
- [Group website] (http://www.fotonik.dtu.dk/english/Research/Communication-technologies/HighSpeed)
