import sys
import os
from mycroft.messagebus.client.ws import WebsocketClient
from mycroft.messagebus.message import Message

if len(sys.argv) == 2:
    messageToSend = sys.argv[1]
elif len(sys.argv) > 2:
    messageToSend = " ".join(sys.argv[2:])
else:
    filename = os.path.basename(__file__)
    print filename
    print "Simple command line interface to the messagebus."
    print "Usage:   messagebus_emit <utterance>\n"
    print "         where <utterance> is treated as if spoken to Mycroft."
    print "Example: " + filename + " mycroft.wifi.start"
    exit()


def onConnected(event=None):
    print "Sending message...'" + messageToSend + "'"
    messagebusClient.emit(Message(messageToSend))
    messagebusClient.close()
    exit()


# Establish a connection with the messagebus
messagebusClient = WebsocketClient()
messagebusClient.on('connected', onConnected)


# This will block until the client gets closed
messagebusClient.run_forever()
