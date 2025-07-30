import os
from dotenv import load_dotenv
from PIL import Image
import io
from fastapi import UploadFile
from google import genai

load_dotenv()

# Gemini API 키 설정
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')

def get_gemini_model():
    """Gemini Pro Vision 모델을 반환합니다."""
    try:
        if not GEMINI_API_KEY:
            print("GEMINI_API_KEY가 설정되지 않았습니다.")
            return None
        client = genai.Client(api_key=GEMINI_API_KEY)
        return client
    except Exception as e:
        print(f"Gemini 모델 초기화 실패: {e}")
        return None

def compress_image_for_gemini(image: Image.Image, max_size: tuple = (1024, 1024), quality: int = 85) -> Image.Image:
    """
    Gemini API 전송을 위해 이미지를 압축합니다.
    
    Args:
        image: 원본 PIL Image
        max_size: 최대 크기 (width, height)
        quality: JPEG 품질 (1-100)
        
    Returns:
        Image.Image: 압축된 이미지
    """
    try:
        # 이미지 크기 조정 (비율 유지)
        image.thumbnail(max_size, Image.Resampling.LANCZOS)
        
        # JPEG로 변환하여 용량 줄이기
        output_buffer = io.BytesIO()
        image.convert('RGB').save(output_buffer, format='JPEG', quality=quality, optimize=True)
        output_buffer.seek(0)
        
        # 압축된 이미지 반환
        compressed_image = Image.open(output_buffer)
        
        # 원본 대비 용량 비교 (디버깅용)
        original_size = len(image.tobytes())
        compressed_size = len(compressed_image.tobytes())
        compression_ratio = (1 - compressed_size / original_size) * 100 if original_size > 0 else 0
        print(f"이미지 압축: {original_size} → {compressed_size} bytes ({compression_ratio:.1f}% 감소)")
        
        return compressed_image
        
    except Exception as e:
        print(f"이미지 압축 실패: {e}")
        return image

async def analyze_photo_and_generate_description(photo: UploadFile) -> str:
    """
    사진을 분석하고 일기용 설명을 생성합니다.
    
    Args:
        photo: 업로드된 사진 파일
        
    Returns:
        str: 사진에 대한 일기용 설명
    """
    try:
        # Gemini API 키가 없으면 기본 설명 반환
        if not GEMINI_API_KEY:
            return "사진이 포함된 일기입니다."
        
        model = get_gemini_model()
        if not model:
            return "사진이 포함된 일기입니다."
        
        # 사진 파일을 PIL Image로 변환
        image_data = await photo.read()
        original_image = Image.open(io.BytesIO(image_data))
        
        # 이미지 압축 (Gemini API 전송용)
        compressed_image = compress_image_for_gemini(original_image)
        
        # Gemini에 전송할 프롬프트
        prompt = """
        이 사진을 보고 사진을 설명할 수 있는 한국어 2-3문장으로 작성해주세요.
        사용자가 무엇을 하였을지 추측하는데 도움이 되도록 작성하시오.
        """
        
        # Gemini API 호출 (압축된 이미지 사용)
        response = model.models.generate_content(
            model="gemini-2.5-flash",
            contents=[prompt, compressed_image]
        )
        
        if response.text:
            return response.text.strip()
        else:
            return "사진이 포함된 일기입니다."
            
    except Exception as e:
        print(f"사진 분석 실패: {e}")
        print(f"GEMINI_API_KEY 설정 여부: {GEMINI_API_KEY is not None}")
        print(f"모델 초기화 여부: {model is not None}")
        return "사진이 포함된 일기입니다." 