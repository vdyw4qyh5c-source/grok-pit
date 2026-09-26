# sergeybondarenko-managed
# First-deploy nginx site. Do not reuse this server_name on another vhost.

server {
    listen 80;
    listen [::]:80;
    server_name www.__DOMAIN__;
    return 301 $scheme://__DOMAIN__$request_uri;
}

server {
    listen 80;
    listen [::]:80;
    server_name __DOMAIN__;

    client_max_body_size 16m;

    location / {
        proxy_pass http://127.0.0.1:__PORT__;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 60s;
    }
}
