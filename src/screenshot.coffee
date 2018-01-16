# Description
#   A hubot script that grabs a screenshot of the given URL and resolution (defaults to 960x1024)
#
# Configuration:
#   HUBOT_SCREENSHOT_SLACK_CHANNEL (The channel to post screenshots)
#   SELENIUM_REMOTE_URL (The selenium grid url)
#   SELENIUM_BROWSER (chrome firefox ..)
#
# Commands:
#   hubot screenshot page <url>
#   hubot screenshot page <url> at <resolution> (ex. 320x748 or iphone 5s)
#
# Notes:
#   This script saves screenshots to the file system where hubot is hosted. This will not work on Heroku
#   The hubot process should be run by a user with write privileges on the directory where hubot is installed
#
# Author:
#   Jason Yost <jyost@gocortexlabs.com>

fs = require("fs") # require fs to write the screenshots to disk
Pageres = require('selenium-webdriver') # selenium library used for taking the screenshots
util = require("util")
request = require("request")

module.exports = (robot) ->
  robot.respond /screenshot page (\S*)?( at )?(\S*)?/i, (msg) ->
    pageres = await new Pageres().forBrowser('chrome').build();
    domain = msg.match[1].replace("http://", "")
    if msg.match[3] == undefined
      size = '960x1024'
    else
      size = msg.match[3]
    dest = './screenshots'
    msg.send "Acquiring screenshot of #{domain} at #{size}"
    #pageres.src(domain, [size]).dest(dest)
    pageres.get(domain);
    pageres.takeScreenshot().then(
    function(image, err) {
        require('fs').writeFile("./screenshots/#{domain.replace(/\//g, "!")}-#{size}.png", image, 'base64', function(err) {
            console.log(err);
        });
        opts = {
          method: 'POST',
          uri: 'https://slack.com/api/files.upload',
          formData: {
            channels: process.env.HUBOT_SCREENSHOT_SLACK_CHANNEL,
            initial_comment: "Screenshot of #{domain} at #{size}",
            token: process.env.HUBOT_SLACK_TOKEN,
            file: fs.createReadStream("./screenshots/#{domain.replace(/\//g, "!")}-#{size}.png")
          }
        }
        request.post opts, (error, response, body) ->
          if error
            robot.logger.error error
          else
            robot.logger.debug 'screenshot posted to slack'
    }
    );
    return
