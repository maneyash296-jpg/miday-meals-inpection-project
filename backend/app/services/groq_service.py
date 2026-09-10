"""NutriGuard AI — Groq LLM Service.

Handles all text-based LLM interactions:  reasoning, explanations,
recommendations, summaries, structured JSON generation.
"""

import json
import asyncio
from typing import Optional, Dict, Any, List

from groq import AsyncGroq
from app.core.config import settings
from app.core.logging import logger


class GroqAIService:
    """Async wrapper around the Groq chat completions API."""

    def __init__(self):
        self.client = AsyncGroq(api_key=settings.GROQ_API_KEY)
        self.model = settings.GROQ_MODEL
        self._max_retries = 3
        self._timeout = 30

    # ── Core helpers ─────────────────────────────────────────────────────────

    async def _chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.3,
        max_tokens: int = 2048,
        response_format: Optional[Dict] = None,
    ) -> str:
        """Send a chat completion request with retry logic."""
        last_error = None
        for attempt in range(1, self._max_retries + 1):
            try:
                kwargs: Dict[str, Any] = {
                    "model": self.model,
                    "messages": messages,
                    "temperature": temperature,
                    "max_tokens": max_tokens,
                }
                if response_format:
                    kwargs["response_format"] = response_format

                response = await asyncio.wait_for(
                    self.client.chat.completions.create(**kwargs),
                    timeout=self._timeout,
                )
                content = response.choices[0].message.content
                if content:
                    return content.strip()
                raise ValueError("Empty response from Groq")
            except asyncio.TimeoutError:
                last_error = TimeoutError(f"Groq request timed out (attempt {attempt})")
                logger.warning(f"Groq timeout attempt {attempt}/{self._max_retries}")
            except Exception as e:
                last_error = e
                logger.warning(f"Groq error attempt {attempt}/{self._max_retries}: {e}")
            if attempt < self._max_retries:
                await asyncio.sleep(2 ** attempt)

        raise last_error or RuntimeError("Groq request failed after retries")

    # ── Public API ───────────────────────────────────────────────────────────

    async def generate_text(
        self,
        prompt: str,
        system_prompt: str = "You are NutriGuard AI, an expert in school nutrition monitoring and food safety.",
        temperature: float = 0.3,
        max_tokens: int = 2048,
    ) -> str:
        """Generate free-form text."""
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt},
        ]
        return await self._chat(messages, temperature=temperature, max_tokens=max_tokens)

    async def generate_json(
        self,
        prompt: str,
        system_prompt: str = "You are NutriGuard AI. Respond ONLY with valid JSON. No markdown, no explanation.",
        temperature: float = 0.1,
        max_tokens: int = 2048,
    ) -> Dict[str, Any]:
        """Generate structured JSON output."""
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt},
        ]
        raw = await self._chat(
            messages,
            temperature=temperature,
            max_tokens=max_tokens,
            response_format={"type": "json_object"},
        )
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            # Try extracting JSON from markdown fences
            if "```" in raw:
                start = raw.find("{")
                end = raw.rfind("}") + 1
                if start >= 0 and end > start:
                    return json.loads(raw[start:end])
            logger.error(f"Failed to parse Groq JSON: {raw[:500]}")
            raise ValueError("Groq returned invalid JSON")

    async def explain_prediction(
        self,
        prediction_type: str,
        predicted_value: float,
        confidence: float,
        risk_level: str,
        features: Dict[str, Any],
        context: str = "",
    ) -> str:
        """Generate a human-readable explanation of an ML prediction."""
        prompt = f"""Explain this {prediction_type} prediction in simple, actionable language for a school administrator:

Prediction: {predicted_value}
Confidence: {confidence:.1%}
Risk Level: {risk_level}
Key Factors: {json.dumps(features, indent=2)}
{f'Context: {context}' if context else ''}

Provide:
1. What the prediction means
2. Why it was made (citing the key factors)
3. What actions should be taken
4. Expected outcome if action is taken vs. not taken

Keep it concise (max 200 words). Use plain language."""
        return await self.generate_text(prompt)

    async def generate_recommendation(
        self,
        evidence: Dict[str, Any],
        context: str = "",
    ) -> Dict[str, Any]:
        """Generate an AI recommendation based on verified evidence."""
        prompt = f"""Based on the following VERIFIED evidence from the NutriGuard monitoring system, generate a recommendation.

Evidence:
{json.dumps(evidence, indent=2)}

{f'Context: {context}' if context else ''}

Return a JSON object with these exact fields:
{{
    "priority": "HIGH" or "MEDIUM" or "LOW",
    "title": "Short actionable title",
    "description": "Detailed description of the recommendation",
    "evidence": ["list of evidence points that support this"],
    "expected_impact": "What improvement is expected",
    "recommended_action": "Specific action to take"
}}

IMPORTANT: Base your recommendation ONLY on the evidence provided. Do NOT invent facts."""
        return await self.generate_json(prompt)

    async def summarize_dashboard(
        self,
        dashboard_data: Dict[str, Any],
        role: str = "teacher",
    ) -> str:
        """Generate a natural-language summary of dashboard data."""
        prompt = f"""Summarize the following school monitoring dashboard data for a {role}.
Focus on:
- Key highlights (good or bad)
- Items that need immediate attention
- Trends

Data:
{json.dumps(dashboard_data, indent=2, default=str)}

Write a concise 3-5 sentence summary in professional tone. Be specific with numbers."""
        return await self.generate_text(prompt, max_tokens=500)

    async def analyze_meal_compliance(
        self,
        expected_items: List[str],
        detected_items: List[Dict[str, Any]],
        scores: Dict[str, float],
    ) -> str:
        """Generate an explanation of meal compliance analysis results."""
        prompt = f"""Explain this school meal compliance analysis:

Expected menu items: {', '.join(expected_items)}
Detected items: {json.dumps(detected_items)}
Scores:
  - Nutrition: {scores.get('nutrition', 0):.1f}/100
  - Quantity: {scores.get('quantity', 0):.1f}/100
  - Hygiene: {scores.get('hygiene', 0):.1f}/100
  - Overall: {scores.get('overall', 0):.1f}/100

Missing items: {', '.join(set(expected_items) - {d.get('name', '') for d in detected_items}) or 'None'}

Provide a brief, professional explanation of:
1. Compliance status
2. Missing items impact
3. Suggested corrective actions

Keep it under 150 words."""
        return await self.generate_text(prompt, max_tokens=400)


# Singleton
groq_service = GroqAIService()
