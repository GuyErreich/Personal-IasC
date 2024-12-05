FROM ghcr.io/epicgames/unreal-engine:dev-slim-5.4.4 AS unreal

# Use a base image with the necessary libraries for Unreal Engine
FROM 961341519925.dkr.ecr.eu-central-1.amazonaws.com/ci-cd/github-runner:latest

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

USER root

# Install prerequisites
# RUN apt-get update && \
#     apt-get install -y \
#     git \
#     build-essential \
#     clang \
#     libxrandr2 \
#     libxinerama1 \
#     libxcursor1 \
#     libxi6 \
#     libgl1-mesa-glx \
#     libvulkan1 \
#     libpulse0 \
#     libsdl2-2.0-0 \
#     libgtk-3-0 \
#     libnss3 \
#     dotnet-sdk-6.0 \
    # && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://github.com/go-task/task/releases/download/v3.8.0/task_linux_amd64.tar.gz -o task.tar.gz \
    && tar -xzvf task.tar.gz \
    && mv task /usr/local/bin/


# # Set up necessary environment variables for Unreal Engine 5
# ENV UE5_ROOT=/UnrealEngine
# ENV PATH="$UE5_ROOT/Engine/Binaries/Linux:$PATH"

# ARG UE_VERSION=5.4.4

# RUN git config --global url."https://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@github.com/".insteadOf "https://github.com/" \
#     && git clone -b "${UE_VERSION}-release" --single-branch "https://github.com/EpicGames/UnrealEngine.git" $UE5_ROOT

# RUN cd $UE5_ROOT && ./Setup.sh && ./GenerateProjectFiles.sh

# RUN ln -s /usr/lib/x86_64-linux-gnu/libicudata.so /usr/lib/x86_64-linux-gnu/libicudata.so.64.1 && \
#     ln -s /usr/lib/x86_64-linux-gnu/libicui18n.so /usr/lib/x86_64-linux-gnu/libicui18n.so.64.1 && \
#     ln -s /usr/lib/x86_64-linux-gnu/libicuio.so /usr/lib/x86_64-linux-gnu/libicuio.so.64.1 && \
#     ln -s /usr/lib/x86_64-linux-gnu/libicutest.so /usr/lib/x86_64-linux-gnu/libicutest.so.64.1 && \
#     ln -s /usr/lib/x86_64-linux-gnu/libicutu.so /usr/lib/x86_64-linux-gnu/libicutu.so.64.1 && \
#     ln -s /usr/lib/x86_64-linux-gnu/libicuuc.so /usr/lib/x86_64-linux-gnu/libicuuc.so.64.1



# Set the working directory
WORKDIR /app

USER runner

COPY --from=unreal --chown=runner:runner /home/ue4/UnrealEngine ./UnrealEngine
COPY ["Automation tools/", "/app"] 

ENV UE_TOOLS=/app/UnrealEngine/Engine/Build/BatchFiles


ENTRYPOINT [ "./entrypoint.sh" ]



