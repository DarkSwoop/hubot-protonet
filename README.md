# Bootstrapped Install on a protonet node
Hubot for Protonet
------------------

1. execute the following commands:

        sudo npm install -g coffee-script
        mkdir -p /home/protonet/apps
        cd /home/protonet/apps
        wget http://digitalbehr.de/hubot.tar.gz
        tar xzvf hubot.tar.gz
        rm hubot.tar.gz

2. create the environment file and customize your hubot settings

        # /home/protonet/.hubot_environment_variables
        export HUBOT_PROTONET_HOST=example.protonet.info
        export HUBOT_PROTONET_USER=hubot_protonet_user_name
        export HUBOT_PROTONET_PASSWORD=hubot_protonet_password
        export HUBOT_PROTONET_PORT=80
        export HUBOT_PROTONET_VERSION=300

3. Try it!

        cd /home/apps/hubot
        ./hubot_start_script start

4. OPTIONAL: a hubot monit script

        # hubot monit script
        check hubot with pidfile /home/protonet/apps/hubot/hubot.pid
          start program = "/home/protonet/apps/hubot/hubot_start_script start"
                    as uid protonet and gid protonet
          stop program = "/home/protonet/apps/hubot/hubot_start_script stop"


# Installing with existing hubot installation
Getting Started
---------------
Add `"hubot-protonet": ">=1.0.0"` to the dependencies in the package.json file.

    "dependencies": {
      "hubot-protonet": ">= 1.0.0",
      "hubot": ">= 2.2.0",
      ...
    }


Configuring the Adapter
-----------------------
The Protonet adapter needs the following environment variables:

    HUBOT_PROTONET_HOST=example.protonet.info
    HUBOT_PROTONET_USER=hubot_protonet_user_name
    HUBOT_PROTONET_PASSWORD=hubot_protonet_password
    HUBOT_PROTONET_PORT=80
    HUBOT_PROTONET_VERSION=300
