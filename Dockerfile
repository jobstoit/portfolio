FROM klakegg/hugo:0.93.2-onbuild AS hugo

FROM nginx
COPY --from=hugo /target /usr/share/nginx/html
