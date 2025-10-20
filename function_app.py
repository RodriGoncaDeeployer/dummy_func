import json
import sys

import azure.functions as func

# Fails when using Python 3.13 docker image and when deployed to Azure Functions using docker container deployment.
# It does not fail when running locally with Python 3.13
from google.api_core.exceptions import NotFound

# ------------------------------------------------------------

func.HttpResponse.mimetype = "application/json"
func.HttpResponse.charset = "utf-8"

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)


@app.function_name(name="endpoint")
@app.route(route="endpoint", methods=["GET"])
def main(req: func.HttpRequest) -> str:
    response: dict[str, str] = {"python": sys.version}

    return func.HttpResponse(json.dumps(response), status_code=200)
