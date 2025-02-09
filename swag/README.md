## Create container via dns validation with a wildcard cert 
Ref: [SWAG Doc](https://docs.linuxserver.io/general/swag/#create-container-via-dns-validation-with-a-wildcard-cert)

Let's assume our domain name is linuxserver-test.com and we would like our cert to also cover www.linuxserver-test.com, ombi.linuxserver-test.com and any other subdomain possible. On the router, we'll forward port 443 to our host server (Port 80 forwarding is optional).

We'll need to make sure that we are using a dns provider that is supported by this image. Currently the following dns plugins are supported: `cloudflare`, `cloudxns`, `digitalocean`, `dnsimple`, `dnsmadeeasy`, `google`, `luadns`, `nsone`, `ovh`, `rfc2136`, `route53`, and many others (see the [docker-swag repo](https://github.com/linuxserver/docker-swag/tree/master/root/defaults/dns-conf) for an up to date list). Your dns provider by default is the provider of your domain name and if they are not supported, it is very easy to switch to a different dns provider. [Cloudflare](https://www.cloudflare.com/) is recommended due to being free and reliable. To switch to Cloudflare, you can register for a free account and follow their steps to point the nameservers to Cloudflare. The rest of the instructions assume that we are using the cloudflare dns plugin.

On our dns provider, we'll create an `A` record for the main domain and point it to our server IP (wan). We'll also create a CNAME for `*` and point it to the `A` record for the domain. On Cloudflare, we'll click on the orange cloud to turn it grey so that it is dns only and not cached/proxied by Cloudflare, which would add more complexities.

Now, let's get the container set up.

With docker cli, we'll first create a user defined bridge network if we haven't already `docker network create lsio`, and then create the container:

```bash
docker create \
  --name=swag \
  --cap-add=NET_ADMIN \
  --net=lsio \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Europe/London \
  -e URL=linuxserver-test.com \
  -e SUBDOMAINS=wildcard \
  -e VALIDATION=dns \
  -e DNSPLUGIN=cloudflare \
  -p 443:443 \
  -p 80:80 \
  -v /home/aptalca/appdata/swag:/config \
  --restart unless-stopped \
  lscr.io/linuxserver/swag
```

And we start the container via docker start swag

With docker compose, we'll use:

```yml
---
services:
  swag:
    image: lscr.io/linuxserver/swag
    container_name: swag
    cap_add:
      - NET_ADMIN
    networks:
      - lsio
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - URL=linuxserver-test.com
      - SUBDOMAINS=wildcard
      - VALIDATION=dns
      - DNSPLUGIN=cloudflare
    volumes:
      - /home/aptalca/appdata/swag:/config
    ports:
      - 443:443
      - 80:80
    restart: unless-stopped
```

Then we'll fire up the container via `docker-compose up -d`

After the container is started, we'll watch the logs with `docker logs swag -f`. After some init steps, we'll notice that the container will give an error during validation due to wrong credentials. That's because we didn't enter the correct credentials for the Cloudflare API yet. We can browse to the location `/config/dns-conf` which is mapped from the host location (according to above settings) `/home/aptalca/appdata/swag/dns-conf/` and edit the correct ini file for our dns provider. For Cloudflare, we'll enter our API token. The API token can be created by going to My Profile->API Tokens and creating a token with the Edit DNS permission on the DNS zones for which you wish to request certificates. In the cloudflare.ini comment out the `dns_cloudflare_email` and `dns_cloudflare_api_key` values, then uncomment `dns_cloudflare_api_token` and add your API token against it.

Once we enter the credentials into the ini file, we'll restart the docker container via `docker restart swag` and again watch the logs. After successful validation, we should see the notice "**Server ready**" and our webserver should be up and accessible at https://www.linuxserver-test.com.
