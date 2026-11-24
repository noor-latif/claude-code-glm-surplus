#!/usr/bin/env python3
"""Live smoke tests for the Surplus model and Anthropic-compatible APIs."""

import base64
import json
import os
import struct
import urllib.request
import zlib


MODELS_URL = "https://api.surplusintelligence.ai/v1/models"
MESSAGES_URL = "https://api.surplusintelligence.ai/anthropic/v1/messages"
PUBLIC_IMAGE_URL = "https://placehold.co/64x64/red/red.png"


def request(url, api_key=None, payload=None):
    headers = {"Accept": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    data = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        headers["anthropic-version"] = "2023-06-01"
        data = json.dumps(payload).encode("utf-8")
    with urllib.request.urlopen(urllib.request.Request(url, data=data, headers=headers), timeout=30) as response:
        return response.status, response.read()


def png_chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)


def red_png():
    width = height = 64
    pixels = b"".join(b"\x00\xff\x00\x00" * width for _ in range(height))
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + png_chunk(b"IHDR", header) + png_chunk(b"IDAT", zlib.compress(pixels)) + png_chunk(b"IEND", b"")


def main():
    api_key = os.environ.get("SURPLUS_API_KEY", "").strip()
    if not api_key:
        raise SystemExit("SURPLUS_API_KEY is required")

    status, body = request(MODELS_URL, api_key)
    if status != 200:
        raise AssertionError(f"model catalog returned HTTP {status}")
    model_ids = {item["id"] for item in json.loads(body)["data"]}
    assert "glm-5.3" in model_ids, "glm-5.3 missing from model catalog"
    assert "qwen3.8-omni-flash" in model_ids, "qwen3.8-omni-flash missing from model catalog"

    # Thinking tokens count against max_tokens on Surplus GLM; disable thinking
    # so exact-match asserts are deterministic at small max_tokens.
    text_payload = {
        "model": "glm-5.3",
        "max_tokens": 64,
        "thinking": {"type": "disabled"},
        "messages": [{"role": "user", "content": "Reply exactly: SURPLUS_TEXT_OK"}],
    }
    status, body = request(MESSAGES_URL, api_key, text_payload)
    assert status == 200, f"text request returned HTTP {status}"
    text_response = json.loads(body)
    assert any("SURPLUS_TEXT_OK" in block.get("text", "") for block in text_response["content"])

    status, body = request(PUBLIC_IMAGE_URL)
    assert status == 200, f"public image request returned HTTP {status}"
    if len(body) < 100:
        body = red_png()
    image_data = base64.b64encode(body).decode("ascii")

    vision_payload = {
        "model": "qwen3.8-omni-flash",
        "max_tokens": 256,
        "thinking": {"type": "disabled"},
        "messages": [{
            "role": "user",
            "content": [
                {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": image_data}},
                {"type": "text", "text": "What color is this image? Reply with one word."},
            ],
        }],
    }
    status, body = request(MESSAGES_URL, api_key, vision_payload)
    assert status == 200, f"vision request returned HTTP {status}"
    vision_response = json.loads(body)
    answer = " ".join(block.get("text", "") for block in vision_response["content"]).strip().lower()
    assert "red" in answer, f"unexpected vision answer: {answer}"

    print("Surplus model catalog: OK")
    print("GLM text routing: OK")
    print("Qwen vision routing: OK")


if __name__ == "__main__":
    main()
