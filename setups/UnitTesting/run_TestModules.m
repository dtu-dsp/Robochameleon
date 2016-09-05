close all
clear

mfullpath = mfilename('fullpath');
mfilename = mfilename();
mpath = strrep(mfullpath, mfilename, '');

testFiles = dir([mpath 'modules']);
testFiles={testFiles.name};

for nn=1:length(testFiles)
   if ~(strcmpi(testFiles{nn},'..') || strcmpi(testFiles{nn},'.'))
       robolog('Running %s... \n', 'NFO', testFiles{nn})
       eval(strrep(testFiles{nn}, '.m', ''))
       robolog('%s finished, press enter for the next test... \n', 'NFO', testFiles{nn})
       pause
   end
end