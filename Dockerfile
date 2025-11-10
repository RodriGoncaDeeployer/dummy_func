FROM mcr.microsoft.com/azure-functions/python:4-python3.13@sha256:f2486500c134e0b406825b3227a91b2097175d4c6a7008575772514567c9bbd5

# Set the working directory
WORKDIR /home/site/wwwroot

# Copy application code
COPY . /home/site/wwwroot

# Install uv
COPY --from=ghcr.io/astral-sh/uv:0.9.8 /uv /uvx /bin/

# Install python dependencies
COPY ./pyproject.toml ./uv.lock /home/site/wwwroot/
RUN uv export --format requirements.txt -o requirements.txt

# Install dependencies to the Azure Functions Python packages directory
RUN pip install -r requirements.txt

# RUN pip install --target="/home/site/wwwroot/.python_packages/lib/site-packages" -r requirements.txt

# Add venv to PATH
# ENV PATH="/home/site/wwwroot/.python_packages/bin:${PATH}"

# Set environment variables to optimize the Python runtime
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
