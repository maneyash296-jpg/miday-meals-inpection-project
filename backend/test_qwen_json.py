import os
from groq import Groq
from dotenv import load_dotenv

load_dotenv()
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

# Test 1: system message forbidding think
try:
    r = client.chat.completions.create(
        model="qwen/qwen3.6-27b",
        messages=[
            {"role": "system", "content": "You are a specialized JSON parser API. NEVER use <think> tags. Do NOT reason. Return strictly JSON."},
            {"role": "user", "content": "Return a JSON object with key 'status' set to 'ok'."}
        ],
        response_format={"type": "json_object"},
        max_tokens=100
    )
    print("Test 1 (system + json_object):\n", r.choices[0].message.content)
except Exception as e:
    print("Test 1 failed:", e)

# Test 2: without response_format but prompt instruction
try:
    r2 = client.chat.completions.create(
        model="qwen/qwen3.6-27b",
        messages=[
            {"role": "user", "content": "Respond strictly with JSON starting immediately with '{' and no other text: {\"status\": \"ok\"}"}
        ],
        max_tokens=100
    )
    print("\nTest 2 (prompt instruction):\n", r2.choices[0].message.content)
except Exception as e:
    print("Test 2 failed:", e)
