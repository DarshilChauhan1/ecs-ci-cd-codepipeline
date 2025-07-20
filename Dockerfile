# Stage 1: Build stage
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm install

# Copy source code
COPY ./src ./src

COPY tsconfig.json ./tsconfig.json

COPY tsconfig.build.json ./tsconfig.build.json

# Build the application
RUN npm run build

CMD ["npm", "run", "start"]

