FROM debian:bullseye

# Update apt cache and install OS packages
RUN apt-get -y -qq update && \
    apt-get -y -qq upgrade && \
    apt-get -y -qq --no-install-recommends install \
        ca-certificates curl git htop sudo tini wget

# Create a new user, so the container can run as non-root
# OBS: the UID and GID must be the same as the user that own the
# input and the output volumes, so there isn't perms problems!!
# It is recommended to create users in the container this way,
# see: https://nickjanetakis.com/blog/running-docker-containers-as-a-non-root-user-with-a-custom-uid-and-gid
# It is recommended to add --no-log-init to prevent security issues,
# see: https://jtreminio.com/blog/running-docker-containers-as-current-host-user/
ARG USER_UID="1000"
ARG USER_GID="1000"
RUN groupadd --gid $USER_GID developer
RUN useradd --no-log-init --uid $USER_UID --gid $USER_GID --shell /bin/bash \
    --comment "Default User Account" --create-home developer

# Change users passwords
RUN echo "root:root" | chpasswd && \
    echo "developer:developer" | chpasswd

# Add non-root user to sudoers and to adm group
# The adm group was added to allow non-root user to see logs
RUN usermod -aG sudo developer && \
    usermod -aG adm developer

# To allow sudo without password
RUN echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer

# Change user
USER developer

# Set HOME
ENV HOME /home/developer

# Change folder
WORKDIR $HOME

# Download vscode installer (latest version)
RUN wget https://go.microsoft.com/fwlink/?LinkID=760868 -O /tmp/vscode.deb

# Install packages required to run vscode IDE
RUN count=$(ls /tmp/vscode.deb | wc -l) && [ $count = 1 ] \
    && apt-get -y -qq --no-install-recommends install \
        # to install vscodium
        libx11-xcb1 libxtst6 libxshmfence-dev \
        libasound2 libgl1 libegl1-mesa \
        # to debug angular from firefox
        firefox-esr \
    || :  # para entender porque :, ver https://stackoverflow.com/a/49348392/5076110

# Install vscode IDE
RUN count=$(ls /tmp/vscode.deb | wc -l) && [ $count = 1 ] \
    && sudo apt-get -y install /tmp/vscode.deb  \
    || :  # para entender porque :, ver https://stackoverflow.com/a/49348392/5076110


# Add Tini (https://github.com/krallin/tini#using-tini)
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]

# Run your program under Tini (https://github.com/krallin/tini#using-tini)
CMD [ "/usr/share/code/code", "--no-sandbox", "--unity-launch" , "--verbose"]
# or docker run your-image /your/program ...


# Command to build the image
#
# docker build --force-rm \
#  --tag vscode:latest \
#  --build-arg USER_UID=$(stat -c "%u" .) \
#  --build-arg USER_GID=$(stat -c "%g" .) \
#  --file Dockerfile .

# OBS: when using wayland, run "xhost +" first and "xhost -" after
#      for more info see: https://unix.stackexchange.com/q/593411
#      or "xhost +SI:localuser:$(id -un)" instead
#      for more info see: https://unix.stackexchange.com/a/359244
# xhost +SI:localuser:"$(id -un)"

# Command to run vscode
# (https://www.py4u.net/discuss/1132959)
#
# docker run --tty --interactive \
#  --env DISPLAY="${DISPLAY}" \
#  --mount type=bind,source=/tmp/.X11-unix,target=/tmp/.X11-unix \
#  --mount type=bind,source="${HOME}"/VSCodeProjects,target=/home/developer/VSCodeProjects \
#  --workdir /home/developer/VSCodeProjects \
#  --network host --ipc host \
#  --detach --rm vscode:latest
