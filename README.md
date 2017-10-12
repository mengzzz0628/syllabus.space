# SylSpace
course management software on syllabus.space


## Installation and Customization

Due to the outdated three-year-old 5.18.2 version of perl still running on MacOS, we do not recommend it.  If you need to install syllabus.space on osx, first learn brew and install a newer perl first.

### Basic Steps:

- on ubuntu, sudo apt install git cpanminus make gcc

* mkdir mysylspacedir ; cd mysylspacedir
* git clone https://github.com/iwelch/syllabus.space
* cd syllabus.space
* sudo bash
*   cpanm --installdeps .  # (takes a while; check that there are no errors! you can run it twice to check)
*   echo "127.0.0.1 syllabus.test corpfin.syllabus.test auth.syllabus.test" >> /etc/hosts
*   perl initsylspace.pl -f
*   cd Model
*   perl MkTestSite.pl
*   cd ..
*   updatedb   # runserver.pl can now self-detect location
*   perl runserver.pl   # smart enough to figure out whether you are running on syllabus.space itself.  use 'p' to force production mode


now point a firefox to http://syllabus.test (not Chrome!).  when done, just ^C out of runserver.pl


### Real Operation

For real operation on syllabus.space (or similar), you will also need to create a 

	<somewhere-else>/SylSpace-Secrets.conf --- SylSpace's working email and your OAUTH facilities

with your private authentication secrets, and link to it in your main SylSpace directory.

    # ln -s <somewhere-else>/SylSpace-Secrets.conf mysylspacedir/SylSpace-Secrets.conf

The contents of this .conf file are illustrated in SylSpace-Secrets.template .  Edit and rename!


## Starting

For use with hypnotoad on syllabus.space, with automatic restart, you can

    # cp SylSpace.service /lib/systemd/system/
    # systemctl start SylSpace
