FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y sudo wget python3

# Create a new user, so the container can run as non-root
# OBS: the UID and GID must be the same as the user that own the
# input and the output volumes, so there isn't perms problems!!
ARG USER_UID="1000"
ARG USER_GID="1000"
RUN groupadd --gid $USER_GID developer
RUN useradd --uid $USER_UID --gid $USER_GID --comment "Default User Account" --create-home developer

# Change users passwords
RUN echo "root:root" | chpasswd && \
    echo "developer:developer" | chpasswd

# Add new user to sudoers
RUN usermod -aG sudo developer

# To allow sudo without password
RUN echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer

# Change user
USER developer
ENV HOME /home/developer

# Change folder
WORKDIR $HOME

# Install vscode
RUN sudo apt-get install -y libx11-xcb1 libxtst6 libxshmfence-dev libasound2
RUN wget https://go.microsoft.com/fwlink/?LinkID=760868 -O vscode.deb
RUN sudo apt-get install -y ./vscode.deb
# Run vscode
CMD /usr/share/code/code --no-sandbox

# Command to build the image
#
# docker build -t vscode .

# Command to run vscode 
# (https://www.py4u.net/discuss/1132959)
#
# docker run -ti --rm --net=host \
#     -e DISPLAY=$DISPLAY \
#     -v /tmp/.X11-unix:/tmp/.X11-unix \
#     vscode
