# harbor_webhook_receiver
This is a deployment for managing harbor via webhooks.

It uses [webhook](https://github.com/adnanh/webhook) as a consumer and parses the webhooks sent by harbor.
This needs to be deployed next your harbor deployment inside of kubernetes and it's service needs to be configured as a reiceiver of webhooks inside your harbor project.
My harbor deployment has the release name of "frodo" so this deployment also has this set up. You'll need to change the deployment accordingly to your harbor set-up.

Only Clair webhooks are implemented right now. This will receive those hooks and run a script (using the harbor admin credentials) to label the scanned image:tag using these labels here:
![harbor-labels](https://github.com/KarstenSiemer/harbor_webhook_receiver/raw/master/harbor_labels.png)

These labels will be created by the application.

The design here is that harbor will be called via an ingress with a tls certificate and to receive webhooks via a service that will do load balancing across all instances of webhook.
Important to note is that the script needs to be executed in a directory of the container where it has write priviledges.
That is done to able to do less http calls to harbor to reduce traffic.
Using normal text files a cache is implemented that remembers if the global labels have already been created and with which id those label are referenced inside harbor. So that, when doing bulk scanns across harbor images those request do not have to be made each time an image is scanned.
