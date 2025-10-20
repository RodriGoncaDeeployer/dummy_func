# ---------------------------------------------------------------------------------------------------
# Stage 1: Base Build Stage
# ---------------------------------------------------------------------------------------------------
FROM mcr.microsoft.com/azure-functions/python:4-python3.13 AS builder

# Set the working directory
RUN mkdir /app
WORKDIR /app

# Set environment variables
ENV PATH="/opt/python/3/bin:$PATH"

# Install uv
COPY --from=ghcr.io/astral-sh/uv:0.9.2 /uv /uvx /bin/

# Install python dependencies
COPY ./pyproject.toml ./uv.lock /app/
RUN uv sync --locked --no-cache --no-dev

# ---------------------------------------------------------------------------------------------------
# Stage 2: Production Stage
# ---------------------------------------------------------------------------------------------------
FROM mcr.microsoft.com/azure-functions/python:4-python3.13

# Set the working directory
WORKDIR /home/site/wwwroot

# Copy virtual environment
COPY --from=builder /app/.venv /venv/.venv

# Add virtual environment to PATH
ENV PATH="/venv/.venv/bin:$PATH"

# Copy application code
COPY . /home/site/wwwroot

# Set environment variables to optimize the Python runtime
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
