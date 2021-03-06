
CHANGES
=======

Version 1.0 Build 8:
--------------------
* Transitioned to iOS 11
* Preparation for first App Store release (after 8 years)

Version 1.0 Build 7:
--------------------
* Transitioned to iOS 7
* Moved from XIBs to a Storyboard

Version 1.0 Build 6:
--------------------
* iPad support disabled (again) with a focus on publishing the iPhone version
* Code revamp to modernise the codebase

Version 1.0 Build 5:
--------------------
* Universal app with iPad support

Version 1.0 Build 4:
--------------------
* Base64-encoded encoded-words are now being decoded.
* User identity information is now in the settings bundle (Full name, email,
  organization)
* Posting of text articles
* Grouping of article threads
* Caching
* Restoration of last view on restart
* Bug fixed where text labels overwrote date labels in tables
* Article read status is now displayed
* Article follow-up
* Email to article author
* Charset in MIME content type is now being recognised in a number of cases
* Format=flowed implemented

Version 1.0 Build 3:
--------------------
* Bug fixed where the new account view checked the validity of the connection,
  kept that connection open.  App crashed when NNTP server timed-out the
  connection.
* Bug fixed where text following an image within an article was not being
  displayed.
* Bug fixed where returning from an article in search results wasn't
  highlighting the correct article listing
* Some basic MIME functionality implemented: quoted-printable, encoded-word
  headers (Q encoding only).
* Search for newsgroups now displays the number of articles in each found group.
