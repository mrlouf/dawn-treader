FROM nginx:alpine

# Copy the HTML file & CSS
COPY ./index.html /usr/share/nginx/html/index.html
COPY ./styles/styles.css /usr/share/nginx/html/styles/styles.css

# Create a custom nginx config to listen on port 8080
RUN echo 'server { \
    listen 8080; \
    server_name localhost; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
