#!/usr/bin/env bash

# Docker aliases (shortcuts)
# List all containers by status using custom format
alias dkpsa='docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'
# Removes a container, it requires the container name \ ID as parameter
alias dkrm='docker rm -f'
# Removes an image, it requires the image name \ ID as parameter
alias dkrmi='docker rmi'
# Lists all images by repository sorted by tag name
alias dkimg='docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}" | sort'
# Lists all persistent volumes
alias dkvlm='docker volume ls'
# Diplays a container log, it requires the image name \ ID as parameter
alias dklgs='docker logs'
# Streams a container log, it requires the image name \ ID as parameter
alias dklgsf='docker logs -f'
# Initiates a session withing a container, it requires the image name \ ID as parameter followed by the word "bash"
alias dkterm='docker exec -it'
# Starts a container, it requires the image name \ ID as parameter
alias dkstrt='docker start'
# Stops a container, it requires the image name \ ID as parameter
alias dkstp='docker stop'


#  https://dev.to/argherna/bash-functions-and-aliases-for-the-beginning-docker-developer-d4
#  https://hackernoon.com/handy-docker-aliases-4bd85089a3b8


# ----------------------

# Clean Old Containers
# `docker ps -a -q -f status=exited` provides a list of container Ids that are 
# in exited status and `docker rm -v` removes those along with their associated
# volumes. Run `docker rm --help` and `docker ps --help` to see what the 
# flags mean.
# Note: If you want anything from these volumes, you should back it up before 
#       doing this.
alias dkcoc='docker rm -v $(docker ps -a -q -f status=exited)'


# Clean Dangling Volumes
# A dangling volume is one that exists and is no longer connected to any 
# containers.
# `docker volume ls -q -f dangling=true` returns the volume names that are not
# connected to any containers and docker volume rm removes them. Run 
# `docker volume rm --help` and `docker volume ls --help` to see what the flags
# mean.
alias dkcdv='docker volume rm $(docker volume ls -q -f dangling=true)'

# Clean Dangling Images
# Docker images are made up of multiple layers and dangling images are layers 
# that have no relationship to any tagged images.
# `docker images -q -f dangling=true` returns the image names that are not 
# related to any tagged images and docker image rm removes them. Run 
# `docker image rm --help` and `docker images --help` to see what the flags
# mean.
alias dkcdi='docker image rm $(docker images -q -f dangling=true)'

function docker_purge_all(){
    dkcoc;
    dkcdv;
    dkcdi;

}