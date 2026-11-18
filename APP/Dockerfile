# Usar la imagen oficial ligera de Nginx basada en Alpine Linux (~10MB)
FROM nginx:alpine

# Copiar nuestra página de bienvenida personalizada
COPY index.html /usr/share/nginx/html/index.html

# Exponer el puerto 80 estándar HTTP
EXPOSE 80

# Iniciar Nginx en primer plano
CMD ["nginx", "-g", "daemon off;"]
