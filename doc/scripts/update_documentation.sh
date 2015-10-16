#/bin/bash
sed -i 's/\r//g' *.pl #Remove windows carriage return from perl scripts
echo "Remember to clone a vanilla version of the repository before updating the documentation!"
cd ..
doxygen Doxyfile
make -C './user manual/latex/'
cp './user manual/latex/refman.pdf' './user manual/Robochameleon Manual.pdf'
cd scripts
git checkout *.pl # Restore original perl scripts

