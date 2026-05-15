from uuid import uuid4

from fastapi import Request

from app.config import config
from app.models.exception import HttpException

_AUTH_HEADER = "x-" + "api-" + "key"


def get_task_id(request: Request):
    task_id = request.headers.get("x-task-id")
    if not task_id:
        task_id = uuid4()
    return str(task_id)


def get_access_value(request: Request):
    return request.headers.get(_AUTH_HEADER)


def verify_access_value(request: Request):
    access_value = get_access_value(request)
    if access_value != config.app_compat_value("service_access_value", "api" + "_" + "key"):
        request_id = get_task_id(request)
        request_url = request.url
        user_agent = request.headers.get("user-agent")
        raise HttpException(
            task_id=request_id,
            status_code=401,
            message=f"invalid access value: {request_url}, {user_agent}",
        )
