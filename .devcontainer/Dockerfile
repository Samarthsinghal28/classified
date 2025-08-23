FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install Bun + PostgreSQL client
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

RUN apt-get update && apt-get install -y postgresql-client
