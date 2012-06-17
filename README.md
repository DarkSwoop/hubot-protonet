Getting Started
===============
You will also need to edit the package.json for your hubot and add the hubot-protonet adapter dependency.

    "dependencies": {
      "hubot-protonet": ">= 1.0.0",
      "hubot": ">= 2.2.0",
      ...
    }

Then save the file, and commit the changes to your hubot's git repository.

Configuring the Adapter
=======================
The Protonet adapter requires the following environment variables:

    HUBOT_PROTONET_HOST
    HUBOT_PROTONET_USER
    HUBOT_PROTONET_PASSWORD
    HUBOT_PROTONET_PORT
    HUBOT_PROTONET_VERSION
