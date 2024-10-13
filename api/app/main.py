from fastapi import FastAPI, HTTPException, staticfiles
from starlette.responses import FileResponse
import os

app = FastAPI()

app.mount("/static", staticfiles.StaticFiles(directory="static"), name="static")

@app.get("/")
async def read_index():
    return FileResponse(os.path.join("static", "index.html"))

@app.get("/hello")
def read_root():
    return {"message": "Hello, World!"}

@app.get("/health")
def read_health():
    return {"message": "Healthy!"}

@app.get("/items/{item_id}")
def read_item(item_id: int, q: str = None):
    if item_id < 0:
        raise HTTPException(status_code=422, detail={
            "type": "int_parsing",
            "loc": [
                "path",
                "item_id"
            ],
            "msg": "Input should be a valid integer greater than zero",
            "input": item_id
        })

    return {"item_id": item_id, "q": q}

