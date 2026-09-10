import os, base64, re, json, time
from groq import Groq
from dotenv import load_dotenv

load_dotenv()
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

with open("test_meal_realistic.jpg", "rb") as f:
    b64_img = base64.b64encode(f.read()).decode("utf-8")

prompt = (
    "You are an AI food analysis expert for the Indian PM POSHAN school Mid-Day Meal program.\n"
    "Analyze this meal photo and respond ONLY with a single valid JSON object, without any markdown formatting, preamble, or commentary.\n"
    "Expected format:\n"
    "{\n"
    '  "food_items": [\n'
    '    {"name": "Rice", "estimated_quantity": 12.0, "unit": "kg", "confidence": 0.92},\n'
    '    {"name": "Dal", "estimated_quantity": 4.5, "unit": "kg", "confidence": 0.88}\n'
    "  ],\n"
    '  "missing_items": [],\n'
    '  "hygiene_indicators": {\n'
    '    "presentation": "good",\n'
    '    "serving_condition": "acceptable",\n'
    '    "utensil_condition": "good"\n'
    "  },\n"
    '  "confidence": 0.91\n'
    "}\n"
    "Guidelines:\n"
    "- Identify food items: Rice, Dal, Sambar, Vegetable Curry, Chapati/Roti, Egg, Fruit, Curd, Milk\n"
    "- Hygiene values: good, acceptable, poor, unknown\n"
    "- Output pure JSON only."
)

t0 = time.time()
try:
    response = client.chat.completions.create(
        model="qwen/qwen3.6-27b",
        messages=[{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64_img}"}}
            ]
        }],
        temperature=0.1,
        max_tokens=650
    )
    content = response.choices[0].message.content or ""
    print(f"Elapsed: {time.time() - t0:.2f}s")
    print("Raw Output Length:", len(content))
    print("Raw preview:\n", content[:300])

    clean = re.sub(r"<think>.*?</think>", "", content, flags=re.DOTALL).strip()
    match = re.search(r"\{.*\}", clean, re.DOTALL)
    if match:
        parsed = json.loads(match.group(0))
        print("\nSUCCESSFULLY EXTRACTED JSON:")
        print(json.dumps(parsed, indent=2))
    else:
        print("\nNo JSON found. Cleaned was:\n", clean)
except Exception as e:
    print("Error:", e)
