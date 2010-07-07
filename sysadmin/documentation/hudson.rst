
Hudson
======

Hudson provides continuous integration services for the Plone core software.

Details
-------

- Available via https://hudson.plone.org. 
    - sites-enabled directory contents managed in svn (http://svn.plone.org/svn/plone/muse-apache/trunk/hudson-ssl)

- "Installed" in /srv/hudson (which means that is where hudson.war lives).

- Run via OS vendor installed supervisor
    - conf.d directory contents managed in svn (http://svn.plone.org/svn/plone/muse-supervisor/trunk/hudson.conf)

- Configured to allow core devs to login (via ldap).
