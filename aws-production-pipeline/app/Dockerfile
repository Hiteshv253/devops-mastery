FROM nginx:alpine

# Copy static assets to the standard nginx HTML folder
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 (routed dynamically by security group config)
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
