# Dockerfile

# ---- Stage 1: Builder ----
# Use an official Node.js image as the base for the build environment.
# The 'alpine' variant is a lightweight Linux distribution.
FROM node:18-alpine AS builder

# Set the working directory inside the container.
# All subsequent commands will be run from this directory.
WORKDIR /usr/src/app

# Copy package.json and package-lock.json first.
# This leverages Docker's layer caching. As long as these files don't change,
# Docker won't re-run 'npm install', speeding up subsequent builds.
COPY package*.json ./

# Install all dependencies, including development dependencies.
# The '--only=production' flag is not used here because you might have build scripts.
RUN npm install

# Copy the rest of the application source code into the container.
COPY . .

# ---- Stage 2: Production ----
# Use a slim, official Node.js image for the final production image.
# This image is smaller and has a reduced attack surface.
FROM node:18-alpine

# Set the working directory for the production stage.
WORKDIR /usr/src/app

# Copy only the production dependencies from the 'builder' stage.
COPY --from=builder /usr/src/app/node_modules ./node_modules

# Copy the application code from the 'builder' stage.
COPY --from=builder /usr/src/app .

# Create a non-root user and switch to it.
# Running as a non-root user is a critical security best practice to
# limit the potential impact of a container compromise.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the port the application runs on.
# This is documentation; it doesn't actually publish the port.
# The port mapping happens in the docker-compose.yml file.
EXPOSE 3000

# Define the command to run the application.
# This is the entry point for the container.
CMD ["npm", "start"]