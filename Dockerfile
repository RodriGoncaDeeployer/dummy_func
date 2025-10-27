FROM mcr.microsoft.com/azure-functions/python:4-python3.13@sha256:2abfe9a6e06cb1b98ff9be0c6d1a858afd8cf11bff5a479f8ef97c221f7c0c47

# Set the working directory
WORKDIR /home/site/wwwroot

# Copy application code
COPY . /home/site/wwwroot

# Install uv
COPY --from=ghcr.io/astral-sh/uv:0.9.2 /uv /uvx /bin/

# Install python dependencies
COPY ./pyproject.toml ./uv.lock /home/site/wwwroot/
RUN uv export --format requirements.txt -o requirements.txt

# Install dependencies to the Azure Functions Python packages directory
RUN pip install --target="/home/site/wwwroot/.python_packages/lib/site-packages" -r requirements.txt

# Set environment variables to optimize the Python runtime
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
