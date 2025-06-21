# backend-api/Dockerfile

# 1. Base Image
FROM node:18-alpine

# 2. Set working directory
WORKDIR /usr/src/app

# 3. Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# 4. Copy the rest of the application code
COPY . .

# 5. Expose the port the app runs on
EXPOSE 8080

# 6. Command to run the application
CMD [ "node", "index.js" ]