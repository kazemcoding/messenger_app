from typing import Dict, List, Optional
from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, WebSocket] = {}

    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        old = self.active_connections.get(user_id)
        if old is not None:
            try:
                await old.close()
            except Exception:
                pass
            # حذف صریح کلید قدیمی قبل از جایگزینی
            self.active_connections.pop(user_id, None)
        self.active_connections[user_id] = websocket
        print(f"✅ User {user_id} connected. Total: {len(self.active_connections)}")

    def disconnect(self, user_id: int, websocket: Optional[WebSocket] = None):
        """
        اگر websocket داده شود، فقط در صورتی حذف می‌کند که همان اتصال فعلی باشد.
        این کار از حذف اشتباهی اتصال جدید توسط اتصال قدیمی جلوگیری می‌کند.
        """
        current = self.active_connections.get(user_id)
        if current is None:
            return
        if websocket is not None and current is not websocket:
            # اتصال فعلی با اتصالی که خطا داده فرق دارد؛ دست نزن
            return
        del self.active_connections[user_id]
        print(f"❌ User {user_id} disconnected. Total: {len(self.active_connections)}")

    def is_online(self, user_id: int) -> bool:
        return user_id in self.active_connections

    def get_online_users(self) -> List[int]:
        return list(self.active_connections.keys())

    async def send_personal_message(self, message: str, user_id: int) -> bool:
        ws = self.active_connections.get(user_id)
        if ws is None:
            return False
        try:
            await ws.send_text(message)
            return True
        except Exception as e:
            print(f"❌ Error sending to {user_id}: {e}")
            # فقط اگر همان اتصال خطادار هنوز فعال است حذف کن
            self.disconnect(user_id, websocket=ws)
            return False

    async def broadcast(self, message: str, exclude_user_id: int = None):
        disconnected = []
        for user_id, connection in list(self.active_connections.items()):
            if exclude_user_id and user_id == exclude_user_id:
                continue
            try:
                await connection.send_text(message)
            except Exception as e:
                print(f"❌ Error broadcasting to {user_id}: {e}")
                disconnected.append((user_id, connection))
        for user_id, connection in disconnected:
            self.disconnect(user_id, websocket=connection)

    async def broadcast_to_users(self, message: str, user_ids: List[int]):
        for user_id in user_ids:
            await self.send_personal_message(message, user_id)


manager = ConnectionManager()