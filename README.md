# SylSpace
course management software on syllabus.space


## Installation and Customization

Due to the outdated three-year-old 5.18.2 version of perl still running on MacOS, we do not recommend it.  If you need to install it there, learn brew to install a newer perl first.

### Basic Steps:

* mkdir mysylspacedir ; cd mysylspacedir
* git clone https://github.com/iwelch/syllabus.space
* cpanm --installdeps .
* sudo 'echo "127.0.0.1 syllabus.test corpfin.syllabus.test auth.syllabus.test" >> /etc/hosts'
* sudo perl initsylspace.pl
* cd Model
* sudo perl MkTestSite.pl
* cd ..
* perl runserver.pl
* and point a firefox to http://syllabus.test (not Chrome!)


### Real Operation

For real operation, you need to create a 
	somewhere-else/SylSpace-Secrets.conf --- SylSpace's working email and your OAUTH facilities
with your private authentication secrets, and link to it in your main SylSpace directory.
    # ln -s somewhere-else/SylSpace-Secrets.conf mysylspacedir/SylSpace-Secrets.conf

For use with hypnotoad and automatic restart, use

    SylSpace.service


## Starting
