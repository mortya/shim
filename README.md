Shim is a super-basic SciDB client that exposes limited SciDB functionality
through a simple HTTP API. It's based on the mongoose web server.

## Notes
Shim supports TLS/SSL encryption and implements PAM
password authentication. The encrypted, authenticated API adds one
new argument to the unencrypted, non-authentication API, but is otherwise
identical. See
[Paradigm4/shim/master/wwwroot/api.html](http://htmlpreview.github.com/?https://raw.github.com/Paradigm4/shim/master/wwwroot/api.html)
for complete details.

The `shim` program must run on the system that a SciDB coordinator runs on.

Note: libscidbclient.so and SciDB's boost libraries must be in shim's library
path. This may entail setting
LD_LIBRARY_PATH=/opt/scidb/<whatever>/lib:/opt/scidb/<whatever>/3rdparty/boost/lib
before
running shim.  You don't have to worry about that if you install and run shim
as a service.

Note: Shim queries are limited to at most 1,000,000 characters.

## HTTP API documentation
See the wwwroot/api.html document for the API documentation, or compile and
start shim running and point a browser to http://localhost:8080/api.html.
You can also preview the api.html page directly from github at:

[Paradigm4/shim/master/wwwroot/api.html](http://htmlpreview.github.com/?https://raw.github.com/Paradigm4/shim/master/wwwroot/api.html)


The wwwroot directory also includes an example simple javascript client.

##Installation from binary packages
This is the fastest/easiest way to install this service.
The author provides a few pre-built binary packages for SciDB on Ubuntu 12.04 here:

* [http://paradigm4.github.io/shim/shim_14.8_amd64.deb](http://paradigm4.github.io/shim/shim_14.8_amd64.deb)
* [http://paradigm4.github.io/shim/shim_14.3-2_amd64.deb](http://paradigm4.github.io/shim/shim_14.3-2_amd64.deb) (Includes requested .htpasswd auth option)
* [http://paradigm4.github.io/shim/shim_14.3_amd64.deb](http://paradigm4.github.io/shim/shim_14.3_amd64.deb)
* [http://paradigm4.github.io/shim/shim_13.12_amd64.deb](http://paradigm4.github.io/shim/shim_13.12_amd64.deb)
* [http://paradigm4.github.io/shim/shim_13.11_amd64.deb](http://paradigm4.github.io/shim/shim_13.11_amd64.deb)
* [http://paradigm4.github.io/shim/shim_13.9_amd64.deb](http://paradigm4.github.io/shim/shim_13.9_amd64.deb)
* [http://paradigm4.github.io/shim/shim_13.6_amd64.deb](http://paradigm4.github.io/shim/shim_13.6_amd64.deb)
* [http://paradigm4.github.io/shim/shim_13.3_amd64.deb](http://paradigm4.github.io/shim/shim_13.3_amd64.deb)

```
# Install with:
sudo gdebi shim_14.8_amd64.deb

# Uninstall with (be sure to uninstall any existing copy before re-installing shim):
apt-get remove shim
```

and for SciDB on RHEL/Centos 6 here:

* [http://paradigm4.github.io/shim/shim-14.8-1.x86_64.rpm](http://paradigm4.github.io/shim/shim-14.8-1.x86_64.rpm)
* [http://paradigm4.github.io/shim/shim-14.3-2.x86_64.rpm](http://paradigm4.github.io/shim/shim-14.3-2.x86_64.rpm) (Includes requested .htpasswd auth option)
* [http://paradigm4.github.io/shim/shim-14.3-1.x86_64.rpm](http://paradigm4.github.io/shim/shim-14.3-1.x86_64.rpm)
* [http://paradigm4.github.io/shim/shim-13.12-1.x86_64.rpm](http://paradigm4.github.io/shim/shim-13.12-1.x86_64.rpm)
* [http://paradigm4.github.io/shim/shim-13.11-1.x86_64.rpm](http://paradigm4.github.io/shim/shim-13.11-1.x86_64.rpm)
* [http://paradigm4.github.io/shim/shim-13.9-1.x86_64.rpm](http://paradigm4.github.io/shim/shim-13.9-1.x86_64.rpm)
* [http://paradigm4.github.io/shim/shim-13.6-1.x86_64.rpm](http://paradigm4.github.io/shim/shim-13.6-1.x86_64.rpm)
* [http://paradigm4.github.io/shim/shim-13.3-1.x86_64.rpm](http://paradigm4.github.io/shim/shim-13.3-1.x86_64.rpm)

```
# Install with:
rpm -i shim-14.8-1.x86_64.rpm
# shim depends on libgomp. If installation fails, install libgomp and try again:
yum install libgomp

# Uninstall with:
yum remove shim
```
I will continue to make binary packages available when new versions of SciDB are released.

##Configuring  shim
The `shim` service script consults the `/var/lib/shim/conf` file for
configuration options. The default configuration options are shown below:
```
auth=login
ports=8080,8083s
scidbport=1239
user=root
tmp=/tmp
```
If an option is missing from the config file, the default value will be used.
The options are:

* `auth` A PAM authentication method (limited to 'login' for now).
* `ports` A comma-delimited list of HTTP listening ports. Append the lowercase
letter 's' to indicate SSL encryption.
* `scidbport` The local port to talk to SciDB on.
* `user` The user that the shim service runs under. Shim can run as a non-root
user, but then SSL authenticated port logins are limited to the user that shim
is running under.
* `tmp` Temporary I/O directory used on the server.

Restart shim to effect option changes with `/etc/init.d/shimsvc restart`.

### Note on the SSL Key Certificate Configuration

Shim uses a cryptographic key certificate for SSL encrypted web connections.
When you instal shim from a binary package, a new certificate key is
dynamically generated and stored in `/var/lib/shim/ssl_cert.pem`. Feel free to
replace the certificate with one of your own. You should then also set the
permissions of the `/var/lib/shim/ssl_cert.pem` file to restrict all read and
write access to the user that shim is running under.  Restricting access
permissions to the SSL certificate is particularly important for general
machines with many untrusted users (an unlikely setting for an installation of
SciDB).


You can alternatively run `shim` from the command line and use command line
switches to set the configuration options. Run `shim -h` to see a full list
of options. When you run shim from a non-standard location, the program
expects to find the ssl_cert.pem file one directory above the wwwroot
directory.

##Compile and Install from Source
Note that because shim is a SciDB client it needs the boost, zlib, log4cpp and
log4cxx development libraries installed to compile. And because shim now uses
PAM authentication, you'll now need the PAM development libraries for your
system installed too. We illustrate installation of Ubuntu build dependencies
below:
```
sudo apt-get install liblog4cpp5-dev liblog4cxx10-dev libboost-dev libboost-system-dev rubygems libpam0g-dev zlib1g-dev lib64z1-dev
sudo apt-get install scidb-14.8-dev scidb-14.8-libboost1.54-all-dev
gem install fpm
```
Note: `scidb-14.8-libboost1.54-all-dev` and `scidb-14.8-dev` correspond to your
installed version of SciDB, replace those package names as required for your
version. Use `apt-get search scidb` to find the exact package names. (On RHEL
platforms, you will need the `scidb-14.8-libboost-devel.x86_64` and
`scidb-14.8-dev.x86_64` packages installed.)

Once the build dependencies are install, build shim with:
```
make
sudo make install

# Or, if SCIDB is not in the PATH, can set a Make variable SCIDB that points
# to the SCIDB home directory, for example for version 14.8:

make SCIDB=/opt/scidb/14.8
sudo make SCIDB=/opt/scidb/14.8 install

```
### Optionally install as a service
You can install shim as a system service so that it just runs all the time with:
```
sudo make SCIDB=/opt/scidb/14.8 service
```
If you install shim as a service and want to change its default options, for example the default HTTP port or port to talk to SciDB on, you'll need to edit the shim configuration file. See the discussion of command line parameters below.
### Optionally build deb or rpm packages
You can build the service version of shim into packages for Ubuntu 12.04 or RHEL/CentOS 6 with
```
make deb-pkg
make rpm-pkg
```
respectively. Building packages requires that certain extra packaging programs are available,
including rpmbuild for RHEL/CentOS and the Ruby-based fpm packaging utility on all systems.

## Usage
```
shim [-h] [-f] [-p <http port>] [-r <document root>] [-s <scidb port>]
```
where, -f means run in the foreground (defaults to background), -h means help.

If you installed the service version, then you can control when shim is running with the usual mechanism, for example:
```
/etc/init.d/shimsvc stop
/etc/init.d/shimsvc start
```

## Uninstall
We explicitly define our SCIDB home directory for Make in the example below:
```
sudo make SCIDB=/opt/scidb/14.8 uninstall
```


## Log files
Shim prints messages to the system log. The syslog file location varies, but can usually be found in /var/log/syslog or /var/log/messages.
