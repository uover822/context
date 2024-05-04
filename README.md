# context

[![Build Status](https://travis-ci.org/msr/msr-context.svg?branch=master)](https://travis-ci.org/msr/msr-context)
[![Gitter Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/msr/msr-org)

This is a repository in the microservice demonstration system for
the [Tao of Microservices](//bit.ly/rmtaomicro) book (chapter 9). This
code is live at [msr.com](http://msr.com). To get started,
visit the [msr](//github.com/msr) repository.

__This microservice provides the context module data functionality.__


## Running

To run this microservice normally, use the tooling describing in
the [msr](//github.com/msr) repository, which shows you how to run
the entire system of microservices (of which this is only one of many) in
production ([Kubernetes](//kubernetes.io)), staging
([Docker](//docker.com)), and development
([fuge](//github.com/apparatus/fuge)) modes.

To run from the terminal for testing and debugging, see
the [Running from the terminal](#running-from-the-terminal) section
below.



## Message flows

The table shows how this microservice acts on the `Accepted` message
patterns and performs appropriate business `Actions`, as a result of
which, new messages are possibly `Sent`.

|Accepted |Actions |Sent
|--|--|--
|`role:context,cmd:get (SC)` |Get context data about a module|
|`role:info,need:part (AO)` |Provide partial module information|`role:info,collect:part (AO)`

(KEY: A: asynchronous, S: synchronous, O: observed, C: consumed)

### Service interactions

![context](context.png?raw=true "context")


## Running from the terminal

This microservice is written in [Java], which you
may need to download and install. Fork and checkout this repository,
and then run `context` inside the repository folder to install its dependencies:

```sh
$ context install
```

To run this microservice separately, for development, debug, or
testing purposes, use the service scripts in the [`srv`](srv) folder:

* [`context-dev.js`](srv/context-dev.js) : run the development configuration 
  with hard-coded network ports.

  ```sh
  $ java[c] -cp .:binaries/* Reach.java
  $ java[c] -cp .:binaries/* Push.java
  ```

  This program exchanges messages on port 4567.
