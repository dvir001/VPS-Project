#!/bin/bash

cd /tmp
wget --quiet http://downloads.sourceforge.net/project/pentbox18realised/pentbox-1.8.tar.gz
tar xvfz pentbox-1.8.tar.gz
cd /tmp/pentbox-1.8/
cat > 231.txt << EOL
2
3
1
EOL
./pentbox.rb < 231.txt
