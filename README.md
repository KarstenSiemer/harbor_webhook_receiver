# harbor_webhook_receiver
This is a deployment for managing harbor via webhooks.

It uses [webhook](https://github.com/adnanh/webhook) as a consumer and parses the webhooks sent by harbor.
This needs to be deployed next your harbor deployment inside of kubernetes and it's service needs to be configured as a reiceiver of webhooks inside your harbor project.
My harbor deployment has the release name of "frodo" so this deployment also has this set up. You'll need to change the deployment accordingly to your harbor set-up.

Only Clair webhooks are implemented right now. This will receive those hooks and run a script (using the harbor admin credentials) to label the scanned image:tag using these labels here:
![harbor-labels](https://github.com/KarstenSiemer/harbor_webhook_receiver/raw/master/harbor_labels.png)

These labels will be created by the application.
