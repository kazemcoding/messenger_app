from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import uvicorn
import os

app = FastAPI()

# ۱. پیدا کردن مسیر پوشه frontend
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
frontend_path = os.path.join(BASE_DIR, "frontend")

# ۲. سرو کردن فایل‌های استاتیک (CSS و JS)
app.mount("/static", StaticFiles(directory=frontend_path), name="static")

# ۳. وقتی کاربر آدرس اصلی (/) رو باز می‌کنه، index.html رو بفرست
@app.get("/")
async def root():
    index_path = os.path.join(frontend_path, "index.html")
    return FileResponse(index_path)

# ۴. وقتی کاربر /static یا /static/ رو باز می‌کنه هم index.html رو بفرست
@app.get("/static")
@app.get("/static/")
async def serve_index():
    index_path = os.path.join(frontend_path, "index.html")
    return FileResponse(index_path)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)