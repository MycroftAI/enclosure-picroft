import sys
import os
from mycroft.messagebus.client.ws import WebsocketClient
from mycroft.messagebus.message import Message

if len(sys.argv) == 2:
    phraseToSay = sys.argv[1]
elif len(sys.argv) > 2:
    phraseToSay = " ".join(sys.argv[1:])
else:
    filename = os.path.basename(__file__)
    print filename
    print "Simple command line interface to the Mycroft system."
    print "Usage:   python " + filename + " <utterance>\n"
    print "         where <utterance> is treated as if spoken to Mycroft."
    print "Example: python " + filename + " \"what time is it\""
    exit()


def onConnected(event=None):
    print "Connected, speaking to Mycroft...'" + phraseToSay + "'"
    messagebusClient.emit(
            Message("recognizer_loop:utterance",
                    data={'utterances': [phraseToSay]}))
    print "sent!"
    messagebusClient.close()
    exit()


# Establish a connection with the messagebus
print "Creating client"
messagebusClient = WebsocketClient()
messagebusClient.on('connected', onConnected)


# This will block until the client gets closed
messagebusClient.run_forever()
