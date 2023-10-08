To import everything from scratch, perform the following steps:

1. Create all businesses by running
rails runner db/import_businesses.rb

This step needs the files vote_info_cn.csv and vote_info_sr.csv

2. Create all votations and link them to a business by running
rails runner db/import_votations.rb

This step also needs the files vote_info_cn.csv and vote_info_sr.csv

3. Create all people and their votes by running
rails runner db/import_nr_people_and_votes.rb 
(for the NR)
and 
rails runner db/import_sr_people_and_votes.rb
(for the SR)

In addition to the previous files, this also needs the files ch_nr_par.csv and ch_sr_par.csv

4. To import image, run
rails runner db/import_images.rb

This needs the directory db/images to be present and populated with the images

5. To (re-)calculate the points for all people, run
bundle exec rake person:update_points