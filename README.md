# SylSpace
course management software on syllabus.space


## Customization

SylSpace should run without difficulty on localhost:3000.  However, operation on a real host needs some customization.  Grep for syllabus.space:

	SylSpace.service --- to where SylSpace is located
	SylSpace-Secrets.conf --- SylSpace's working email and your OAUTH facilities
	Controller/AuthEmailer --- ditto
	serve-*.sh --- starting a quick morbo production, development; or hypnotoad server

you can ignore mentions in the FAQ.

## Starting

    # sudo initsylspace.pl                ## create /var/sylspace/
    # cd Model ; perl Model.t ; cd ..     ## create some users, courses, and other aspects
    # morbo -v SylSpace                   ## run, or ./serve-development.sh
