#!/usr/bin/bash
perl -p -i -e 's/\s/\n/g' nytimes/trump
perl -p -i -e 's/\s/\n/g' nytimes/trump.stemmed
./make_hist.prl < nytimes/trump.stemmed > nytimes/trump.hist