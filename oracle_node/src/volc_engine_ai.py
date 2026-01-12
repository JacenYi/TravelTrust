import json
import logging
import httpx
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)


class AiRequestMessage:
    """AI request message class"""
    def __init__(self, role: str, content: str):
        self.role = role
        self.content = content

    def to_dict(self) -> Dict[str, str]:
        return {
            "role": self.role,
            "content": self.content
        }


class AiRequest:
    """AI model request class"""
    def __init__(self, model: str, messages: List[AiRequestMessage], 
                 temperature: float = 0.7, top_p: float = 1.0, 
                 max_tokens: int = 2000, stream: bool = False):
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.top_p = top_p
        self.max_tokens = max_tokens
        self.stream = stream

    def to_dict(self) -> Dict[str, Any]:
        return {
            "model": self.model,
            "messages": [msg.to_dict() for msg in self.messages],
            "temperature": self.temperature,
            "top_p": self.top_p,
            "max_tokens": self.max_tokens,
            "stream": self.stream
        }


class AiResponse:
    """AI model response class"""
    def __init__(self):
        self.id: str = ""
        self.object: str = ""
        self.created: int = 0
        self.model: str = ""
        self.choices: List[Dict[str, Any]] = []
        self.usage: Dict[str, int] = {}

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "AiResponse":
        response = cls()
        response.id = data.get("id", "")
        response.object = data.get("object", "")
        response.created = data.get("created", 0)
        response.model = data.get("model", "")
        response.choices = data.get("choices", [])
        response.usage = data.get("usage", {})
        return response

    @property
    def content(self) -> str:
        """Get the content of the first choice"""
        if self.choices and len(self.choices) > 0:
            choice = self.choices[0]
            if isinstance(choice, dict) and "message" in choice:
                message = choice["message"]
                if isinstance(message, dict) and "content" in message:
                    return message["content"]
        return ""


class VolcEngineAI:
    """Volc Engine AI service wrapper"""
    def __init__(self, api_key: str, api_url: str = "https://ark.cn-beijing.volces.com/api/v3/bots/chat/completions"):
        self.api_key = api_key
        self.api_url = api_url
        self.client = httpx.AsyncClient(timeout=30.0)

    async def generate(self, request: AiRequest) -> AiResponse:
        """Call AI to generate response"""
        try:
            logger.info(f"Generating AI response with model: {request.model}, stream mode: {request.stream}")
            
            # Build request headers
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.api_key}"
            }
            
            # Build request body
            request_data = request.to_dict()
            
            # Add stream_options parameter (if it's a streaming request)
            if request.stream:
                request_data["stream_options"] = {
                    "include_usage": True
                }
            
            logger.debug(f"AI Request Payload: {json.dumps(request_data, ensure_ascii=False)}")
            
            # Send request
            response = await self.client.post(
                self.api_url,
                headers=headers,
                json=request_data
            )
            
            response.raise_for_status()
            
            # Process response
            response_data = response.json()
            logger.debug(f"Received API response: {json.dumps(response_data, ensure_ascii=False)}")
            
            return AiResponse.from_dict(response_data)
            
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error occurred: {e.response.status_code} - {e.response.text}")
            raise
        except Exception as e:
            logger.error(f"Error generating AI response: {str(e)}")
            raise
    
    async def audit_review_content(self, content: str, model_id: str) -> bool:
        """Audit review content"""
        try:
            messages = [
                AiRequestMessage(
                    role="system",
                    content="You are a content moderation expert. Please determine if the provided content complies with public order and good customs, and whether it contains inappropriate information. If the content is compliant, return 'Approved'; if it contains inappropriate information, return 'Rejected'. Only return 'Approved' or 'Rejected', do not add any other content."
                ),
                AiRequestMessage(
                    role="user",
                    content=content
                )
            ]
            
            request = AiRequest(
                model=model_id,
                messages=messages,
                temperature=0.0,
                max_tokens=10
            )
            
            response = await self.generate(request)
            result = response.content.strip()
            
            logger.info(f"Content audit result for '{content}': {result}")
            # Handle AI response - only check for English "Approved" since system prompt is now in English
            return result == "Approved"
            
        except Exception as e:
            logger.error(f"Error auditing review content: {str(e)}")
            # If audit fails, return False by default (strict mode)
            return False
    
      
    async def generate_summary_from_input(self, summary_input: str, model_id: str) -> str:
        """Generate review summary from constructed input string"""
        try:
            messages = [
                AiRequestMessage(
                    role="system",
                    content="You are a professional tourist attraction review summary expert. Please generate a detailed summary report based on the provided scenic spot information and review content."
                ),
                AiRequestMessage(
                    role="user",
                    content=summary_input
                )
            ]
            
            request = AiRequest(
                model=model_id,
                messages=messages,
                temperature=0.7,
                max_tokens=2000
            )
            
            response = await self.generate(request)
            summary_content = response.content.strip()
            
            logger.info(f"Generated summary from input: {summary_content}")
            return summary_content
            
        except Exception as e:
            logger.error(f"Error generating summary from input: {str(e)}")
            raise
    
    async def close(self):
        """Close HTTP client"""
        await self.client.aclose()
