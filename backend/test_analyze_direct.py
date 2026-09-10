import httpx

r = httpx.post("http://localhost:8000/api/v1/auth/login", data={"username": "admin@nutriguard.gov.in", "password": "password123"})
token = r.json()["access_token"]
headers = {"Authorization": f"Bearer {token}"}

with open("test_meal_realistic.jpg", "rb") as f:
    r = httpx.post(
        "http://localhost:8000/api/v1/meals/analyze-direct",
        headers=headers,
        files={"file": ("meal.jpg", f, "image/jpeg")},
        data={"students_served": 250, "expected_items_csv": "Rice,Dal,Vegetable Curry"},
        timeout=30
    )

print("HTTP Status Code:", r.status_code)
if r.status_code == 200:
    data = r.json()
    print("AI Evaluation Status:", data["status"])
    print("Overall Quality Score:", data["overall_score"], "/ 100")
    print("Nutrition Score:", data["nutrition_score"], "/ 100")
    print("Quantity Score:", data["quantity_score"], "/ 100")
    print("Hygiene Score:", data["hygiene_score"], "/ 100")
    print("Detected Items:", [f"{i['name']} ({i['confidence']:.0%})" for i in data["vision_result"]["food_items"]])
    print("Groq AI Explanation:", data["explanation"][:200])
else:
    print("Error:", r.text[:300])
