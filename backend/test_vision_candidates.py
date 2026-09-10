import os, base64
from groq import Groq
from dotenv import load_dotenv

load_dotenv()
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

with open("test_meal_realistic.jpg", "rb") as f:
    b64_img = base64.b64encode(f.read()).decode("utf-8")

candidate_models = ["openai/gpt-oss-20b", "openai/gpt-oss-120b", "groq/compound", "groq/compound-mini"]

for model in candidate_models:
    try:
        r = client.chat.completions.create(
            model=model,
            messages=[{
                "role": "user",
                "content": [
                    {"type": "text", "text": "What is in this image?"},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64_img}"}}
                ]
            }],
            max_tokens=50
        )
        print(f"Model {model} SUPPORTS VISION! Response:", r.choices[0].message.content[:100])
    except Exception as e:
        print(f"Model {model} failed vision:", str(e)[:120])
