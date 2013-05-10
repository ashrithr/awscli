awscli
======

Amazon Web Service(s) Command Line Interface

[![Gem Version](https://badge.fury.io/rb/awscli.png)](http://badge.fury.io/rb/awscli) [![Dependency Status](https://gemnasium.com/ashrithr/awscli.png)](https://gemnasium.com/ashrithr/awscli)  [![Code Climate](https://codeclimate.com/github/ashrithr/awscli.png)](https://codeclimate.com/github/ashrithr/awscli)

Provides the following interface:

- Elastic Cloud Compute (EC2)
- Auto Scaling Group (AS)
- Simple Storage Service (S3)
- AWS Identity and Access Management Interface (IAM)
- Elastic MapReduce (EMR)
- DynamoDB

More interfaces are in development.


To Install Use:

```
sudo gem install awscli
```

Note: `awscli` depends on nokogiri gem which needs to be compiled and dynamically linked against both libxml2 and libxslt, for installing dependencies follow this link:
<http://nokogiri.org/tutorials/installing_nokogiri.html>

For help using cli:

`awscli help`

For help on individual Interfaces:

```
$ awscli <interface> help
```

Licence:

`awscli` is released under the terms of the MIT License, see the included LICENSE file.
