
Services
========

These are (some of) the services that the Plone.org infrastructure team is currently responsible for:

Plone.org
---------

One of the main responsibilities of the Plone.org admins team is to keep the plone.org
website running smoothly. This includes the deployment of frequent "dot releases",
major upgrades (e.g. Plone 3 → Plone 4), and monitoring system performance.

http vs https
~~~~~~~~~~~~~

There are two http server configs running on plone.org: one nginx instance for ssl and
one for https. The https nginx is a FreeBSD port install and is configured and
controlled in the standard /usr/local/etc area. The http server config is
deployed via a buildout configuration in /srv/plone.org.

.. figure:: plone.org.gv.png
   :width: 100 %
   :alt: Diagram of services powering plone.org and their interconnections
   
   Diagram of services powering plone.org and their interconnections (validated on 11th of March, 2011)

   Varnish running on port 80 (http), nginx running on port 443 (https) and 
   pound running on port 5020 are FreeBSD port installs. 

Development
~~~~~~~~~~~

To get started, you should familiarize yourself with the combined buildout and policy 
product located here: http://dev.plone.org/plone/browser/Products.PloneOrg/trunk.

To develop locally, follow these steps::

    $ svn co https://svn.plone.org/svn/plone/Products.PloneOrg/trunk Products.PloneOrg
    (edit buildout.cfg to make it extend the develop.cfg configuration instead of production)
    $ python2.6 bootstrap.py
    $ bin/buildout
    $ bin/instance fg

See the README in this package for more information on running a themed copy
of the site with real data.

Issues
~~~~~~

You can find a list of things that need to be fixed here::

    https://dev.plone.org/plone/report/48

Deployment
~~~~~~~~~~

You will need core developer access to commit your changes to the PloneOrg package. You 
can read about that here: http://plone.org/documentation/manual/plone-core-developer-reference/overview/contributing.

Contact the `admins team`_ or join #plone.org on irc.freenode.net to discuss deployment of
your changes!

If you are an admin, you can deploy changes to staging and production servers.

Staging
'''''''

Changes to production server should be tested at staging server available at http://staging.plone.org:6021/ that is variance of production buildout.

- Commit your changes to SVN and merge your changes into staging branch::

    $ cd Products.PloneOrg
    $ svn ci
    $ cd ..
    $ svn co https://svn.plone.org/svn/plone/plone.org/Products.PloneOrg/branches/interra-staging-ticket11435 Products.PloneOrg-staing
    ...
    $ cd Products.PloneOrg-staing
    $ svn merge https://svn.plone.org/svn/plone/plone.org/Products.PloneOrg/trunk
    --- Merging r48153 through r48187 into '.':
    U    src/Products/PloneOrg/skins/ploneorg/login.js
    U    src/Products/PloneOrg/skins/ploneorg/newplone.css
    U    static/plone.html
    U    static/plone-wide.html

    $ svn ci -m "Merged from [log:/plone.org/Products.PloneOrg/trunk#48153:48187 trunk]"
    Sending        .
    Sending        src/Products/PloneOrg/skins/ploneorg/login.js
    Sending        src/Products/PloneOrg/skins/ploneorg/newplone.css
    Sending        static/plone-wide.html
    Sending        static/plone.html
    Transmitting file data ....
    Committed revision 48188.

- Deploy to staging server from working copy of PloneOrg buildout (staging branch)::

    $ bin/fab staging deploy
    [staging.plone.org] Executing task 'deploy'
    [staging.plone.org] sudo: nice svn up
    [staging.plone.org] out: U    src/Products/PloneOrg/skins/ploneorg/login.js
    [staging.plone.org] out: U    src/Products/PloneOrg/skins/ploneorg/newplone.css
    [staging.plone.org] out: U    static/plone.html
    [staging.plone.org] out: U    static/plone-wide.html
    [staging.plone.org] out:  U   .
    [staging.plone.org] out: Updated to revision 48188.
    [staging.plone.org] out: 
    [staging.plone.org] sudo: nice bin/buildout
    [staging.plone.org] out: ---------------------------------------------------------
    [staging.plone.org] out: The current global buildout threat level is:   HIGH  
    [staging.plone.org] out: ---------------------------------------------------------
    [staging.plone.org] out: mr.developer: Queued 'Products.ExternalStorage' for checkout.
    [staging.plone.org] out: mr.developer: Queued 'Products.FoundationMember' for checkout.
    ...
    [staging.plone.org] out: static/plone-wide.html
    [staging.plone.org] out: *************** PICKED VERSIONS ****************
    [staging.plone.org] out: [versions]
    [staging.plone.org] out: 
    [staging.plone.org] out: *************** /PICKED VERSIONS ***************
    [staging.plone.org] out: 
    [staging.plone.org] sudo: nice bin/supervisorctl reload
    [staging.plone.org] out: Restarted supervisord
    [staging.plone.org] out: 

    Done.
    Disconnecting from staging.plone.org... done.


Production
''''''''''

You can deploy changes to production server like this::

    $ ssh plone.org
    $ cd /srv/plone.org
    $ sudo -u zope svn up
    $ sudo -u zope bin/buildout

Then restart the instances as instructed below.

Restarting
''''''''''

If you are a member of the admins team, you may be occasionally asked to login, svn up, run buildout, and restart the instances.
To do that, you can use the following commands::

    $ ssh plone.org
    $ cd /srv/plone.org
    $ sudo -u zope svn up 
    $ sudo -u zope bin/buildout
    $ sudo -u zope bin/supervisorctl restart plone.org-client-{1,2,3,4} ; sleep 120 ; sudo -u zope bin/supervisorctl restart plone.org-client-{5,6,7,8}

Clearing the cache
~~~~~~~~~~~~~~~~~~

If you are a member of the admins team, you may be occasionally asked to login and clear the cache.
To do that, you can use the following commands::

    $ ssh plone.org
    $ telnet localhost 81

At which point you will be in the Varnish management console and can do things like `url.purge /`::

    plone01:/usr/local/etc/rc.d$ telnet localhost 81
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.
    200 154
    -----------------------------
    Varnish HTTP accelerator CLI.
    -----------------------------
    Type 'help' for command list.
    Type 'quit' to close CLI session.

    url.purge /
    200 0

When you are done, use CTRL-] to return to the telnet console, at which point you may `close`::

    ^]
    telnet> close
    Connection closed.

Other services
~~~~~~~~~~~~~~

Some services are not included in the buildout, including:

- Varnish
- Pound
- LDAP
- Postfix

Generally speaking, these services are controlled "BSD-style" and are located in /usr/local.
So for example to restart nginx, you can do the following::

    $ /usr/local/etc/rc.d/pound restart

Note the configuration files for some of these services are version controlled, e.g.
http://svn.plone.org/svn/plone/plone01-pound/trunk/.

All configuration files of interest are either created by buildout or included in version control.

.. _`admins team`: mailto:admins@lists.plone.org

Adding users to sudo group
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

plone.org runs on FreeBSD. The commands might differ from what you have learn from Linux.

* sudoers group is called ``wheel``

* http://www.freebsd.org/doc/handbook/users-groups.html

Maybe::

        pw groupmod wheel -m mikko

Mailman
-------

These are the details of the Mailman service running on aneka.plone.org (CNAME lists.plone.org).

Specs
~~~~~

- Version = 2.1.6 (source build) 
- Location = /srv/lists.plone.org/mailman
- Path = /Applications/mailman (symlinked Applications = /srv/lists.plone.org)

Notes
~~~~~

Mailman was built from source due to the need to pass selected parameters on install. The original location on dues was copied on the aneka install and on the original the libs and archives where symlinked as well, the newer install uses the same method symlinking from the server release location to /Applications/mailman/archives/

The path is /Applications symlinked as that was what was most convenient to use at the time due to the person migrating it using that path on there own system.

Web interface for Mailman is via the https nginx (/usr/local/etc/nginx)

Postfix
-------

Specs
~~~~~

- Postfix: Version = 2.3.8 
- Location = /usr/lib/postfix 
- relay domains = lists.plone.org 
- Allowed domains = aneka.plone.org, localhost.plone.org, localhost
- Spamassassin: Version = 3.2.3 
- Perl version = 5.8.8

Notes
~~~~~

Spamassassin is using Bayes system rules with a current score of 5.0 – at the moment it delivers the mail marked as spam so a judgement can be made on if it is spam or not until a good balance in terms of scoring has been found, they can then be temporarily stored in a separate mailbox or discarded automatically.

Subversion
----------

The Plone.org admins are responsible for the management of the following
repositories:

- https://svn.plone.org/svn/archetypes
- https://svn.plone.org/svn/collective
- https://svn.plone.org/svn/foundation
- https://svn.plone.org/svn/plone


Servers
~~~~~~~

The primary server is OSU's deus.plone.org with a mirror to XS4ALL's 
antiloop.plone.org.

Users
~~~~~

The repositories are owned by the ``www-data`` user.

Mirroring
~~~~~~~~~

In /etc/cron.hourly on deus we have::

    #!/bin/sh

    LOCKFILE=/var/lock/cron.svn-mirror

    if [ -x /usr/bin/lockfile-create ] ; then
        lockfile-create $LOCKFILE
        if [ $? -ne 0 ] ; then
            cat <<EOF

    Unable to run /etc/cron.daily/svn-mirror because lockfile $LOCKFILE
    acquisition failed. This probably means that the previous day's
    instance is still running. Please check and correct if necessary.

    EOF
            exit 1
        fi

        # Keep lockfile fresh
        lockfile-touch $LOCKFILE &
        LOCKTOUCHPID="$!"
    fi

    for repo in archetypes plone collective ; do
            su www-data -c "svnsync sync https://svn-mirror.plone.org/svn/$repo --non-interactive" > /dev/null
    done

    if [ -x /usr/bin/lockfile-create ] ; then
        kill $LOCKTOUCHPID
        lockfile-remove $LOCKFILE
    fi

Troubleshooting
~~~~~~~~~~~~~~~

Occasionally when running svnsync on ``deus`` you may get an error like this::

    Failed to get lock on destination repos…

At which point running the following command should help::

    svn pdel --revprop -r 0 svn:sync-lock https://svn-mirror.plone.org/svn/<repo>

LDAP
----

Currently the LDAP services are configured to have all updates happen via plone.org running on plone01 (the master LDAP directory) and are replicated through the standard ssl channel through to the other servers such as dues and hudson.plone.org and plone.net.

Replication occurs periodically and each of the servers are configured to receive use there local openldap service which listens on port 636 for requests from plone01.

plone01.sixfeetup.com sends data via ssl but does not listen on that port and will not respond to connection requests.

Hudson
------

Hudson provides continuous integration services for the Plone core software.

Details
~~~~~~~

- Available via https://hudson.plone.org. 
    - sites-enabled directory contents managed in svn (http://svn.plone.org/svn/plone/muse-apache/trunk/hudson-ssl)

- "Installed" in /srv/hudson (which means that is where hudson.war lives).

- Run via OS vendor installed supervisor
    - conf.d directory contents managed in svn (http://svn.plone.org/svn/plone/muse-supervisor/trunk/hudson.conf)

- Configured to allow core devs to login (via ldap).

Planet
------

Planet Plone (http://planet.plone.org) aggregates blog feeds of various community members to a single website, for the enjoyment of all.

Details
~~~~~~~

The Plone planet runs Venus planet software (http://intertwingly.net/code/venus/) and is installed on deus.plone.org in::

    /srv/planet.plone.org/venus/plone

Its configuration is version controlled here::

    https://svn.plone.org/svn/plone/planet/trunk

And it is updated via a cron job on deus.plone.org here::

    /etc/cron.d/planet

That file looks like this::

    # Update the planet site every 10 minutes
    MAILTO=admins@plone.org
    */10 * * * * planet /srv/planet.plone.org/bin/update >/dev/null 2>/dev/null


Deploy changes
''''''''''''''

You can deploy changes like so:

    - Deploy changes commited to https://svn.plone.org/svn/plone/planet/trunk via::

        $ cd /srv/planet.plone.org/venus/plone
        $ sudo -u planet svn up 

    - Update manually by running the following command on deus.plone.org as the planet user::

        $ sudo -u planet /srv/planet.plone.org/bin/update

Trac
----

This section contains information about the community managed trac instances located at dev.plone.org.


Theme
~~~~~

By default, trac is themed along with the rest of plone.org. If you prefer the default Trac theme, visit this url (which sets a cookie):

- http://dev.plone.org/trac-theme

To go back to the Plone theme, visit this url:

- http://dev.plone.org/plone-theme


SSL Certificates
----------------

The Plone Foundation has a wildcard SSL certificate
for \*.plone.org. This is currently used via apache2
on dev.plone.org and svn.plone.org.

The certificate and key files are at
/srv/deus.plone.org/etc/ssl . Please exercise all
care in handling of the key file: it should be treated as a secret, 
highly confidential and protected from unintended disclosure.

We also have a non-wildcard certificate for www.plone.org/plone.org.
The key and cert files are on plone.org in /usr/local/etc/nginx/vhosts/ssl.*

