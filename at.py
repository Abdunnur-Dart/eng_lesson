import asyncio
from datetime import datetime
import json
import queue
from bleak import BleakClient
from vosk import KaldiRecognizer, Model
import sounddevice as sd

# Замените на реальный MAC-адрес вашей ESP32-C3
ADDRESS = "XX:XX:XX:XX:XX:XX"
MODEL_PATH = "vosk-model-small-ru-0.22"

print("Загрузка языковой модели Vosk...")
model = Model(MODEL_PATH)
q = queue.Queue()


def audio_callback(indata, frames, time, status):
  if status:
    print(status, flush=True)
  q.put(bytes(indata))


async def main():
  print("Подключаемся к роботу по Bluetooth...")
  async with BleakClient(ADDRESS) as client:
    print("Подключено! Слушаю команды... Говорите в микрофон.")

    with sd.RawInputStream(
        samplerate=16000,
        blocksize=8000,
        dtype="int16",
        channels=1,
        callback=audio_callback,
    ):
      rec = KaldiRecognizer(model, 16000)
      while True:
        data = q.get()
        if rec.AcceptWaveform(data):
          res = json.loads(rec.Result())
          text = res.get("text", "").lower()

          if text:
            print(f"Распознано: {text}")
            cmd = None

            # «Привет» / «Доброе утро»
            if "привет" in text or "доброе утро" in text or "здравствуй" in text:
              print("Робот: Привет! Рад тебя видеть!")
              cmd = "h"

            # «Ты мне нравишься» / «Ты любишь меня?»
            elif (
                "нравишься" in text
                or "любишь меня" in text
                or "люблю" in text
                or "ты любишь" in text
            ):
              print("Робот: <3")
              cmd = "g"  # Анимация подарка / сердечка

            # «Как дела?» / «Что делаешь?»
            elif "как дела" in text or "что делаешь" in text:
              print("Робот размышляет...")
              cmd = "l"

            # «Скучно!»
            elif "скучно" in text:
              print("Робот: Не скучай, потыкай мне в носик (сенсор)!")
              cmd = "r"

            # «Как тебя зовут?»
            elif "зовут" in text:
              print("Робот: Меня зовут RobotFriend, я твой робот-друг!")
              cmd = "h"

            # «Который час?» / Время
            elif "час" in text or "время" in text:
              now = datetime.now().strftime("%H:%M")
              print(f"Робот: Сейчас {now}")
              cmd = "h"

            # «Тихо» / «Спать» / «Отдохни»
            elif "спать" in text or "тихо" in text or "отдохни" in text:
              print("Робот уходит в спящий режим.")
              cmd = "s"

            if cmd:
              await client.write_gatt_char(
                  "6E400002-B5A3-F393-E0A9-E50E24DCCA9E", cmd.encode()
              )
              print(f"Команда '{cmd}' отправлена роботу.")


if __name__ == "__main__":
  asyncio.run(main())
