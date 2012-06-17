Getting Started
===============
Add `"hubot-protonet": ">=1.0.0"` to the dependencies in the package.json file.

    "dependencies": {
      "hubot-protonet": ">= 1.0.0",
      "hubot": ">= 2.2.0",
      ...
    }


Configuring the Adapter
=======================
The Protonet adapter needs the following environment variables:

    HUBOT_PROTONET_HOST=example.protonet.info
    HUBOT_PROTONET_USER=hubot_protonet_user_name
    HUBOT_PROTONET_PASSWORD=hubot_protonet_password
    HUBOT_PROTONET_PORT=80
    HUBOT_PROTONET_VERSION=300
