import asyncio
import time
import sys
import os
from dotenv import load_dotenv

# 确保从 backend 目录加载 .env 文件
backend_dir = os.path.join(os.path.dirname(__file__), "backend")
load_dotenv(os.path.join(backend_dir, ".env"))

sys.path.insert(0, backend_dir)

from app.clients.ark_vlm_client import ArkVLMClient
from app.clients.ark_llm_client import ArkLLMClient
from app.clients.real_jd_client import RealJDClient
from app.clients.real_pdd_client import RealPDDClient
from app.config import settings


async def test_vlm():
    print("\n" + "=" * 60)
    print("测试 VLM (视觉识别) API")
    print("=" * 60)
    
    if not settings.ark_api_key or not settings.ark_vlm_endpoint_id:
        print("❌ VLM API 密钥未配置")
        return None
    
    try:
        vlm_client = ArkVLMClient()
        
        # 创建一个简单的测试图片 (纯黑 1x1)
        test_image = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xff\xdb\x00C\x00\x03\x02\x02\x02\x02\x02\x03\x02\x02\x02\x03\x03\x03\x03\x04\x06\x04\x04\x04\x04\x04\x08\x06\x06\x05\x06\x09\x08\x0a\x0a\x09\x08\x09\x09\x0a\x0c\x0f\x0c\x0a\x0b\x0e\x0b\x09\x09\x0d\x11\x0d\x0e\x0f\x10\x10\x11\x10\x0a\x0c\x12\x13\x12\x10\x13\x0f\x10\x10\x10\xff\xc0\x00\x0b\x08\x00\x01\x00\x01\x01\x01\x11\x00\xff\xc4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xff\xc4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xda\x00\x08\x01\x01\x00\x00?\x00T\x9f\xff\xd9"
        
        start_time = time.time()
        result = await vlm_client.recognize(test_image)
        elapsed = time.time() - start_time
        
        print(f"✅ VLM 调用成功 (耗时: {elapsed:.2f}秒)")
        print(f"   识别结果: {result}")
        return elapsed
        
    except Exception as e:
        print(f"❌ VLM 调用失败: {e}")
        import traceback
        traceback.print_exc()
        return None


async def test_llm():
    print("\n" + "=" * 60)
    print("测试 LLM (语言模型) API")
    print("=" * 60)
    
    if not settings.ark_api_key or not settings.ark_llm_endpoint_id:
        print("❌ LLM API 密钥未配置")
        return None
    
    try:
        llm_client = ArkLLMClient()
        
        start_time = time.time()
        result = await llm_client.expand_keywords(["运动鞋"])
        elapsed = time.time() - start_time
        
        print(f"✅ LLM 调用成功 (耗时: {elapsed:.2f}秒)")
        print(f"   结果: {result}")
        return elapsed
        
    except Exception as e:
        print(f"❌ LLM 调用失败: {e}")
        import traceback
        traceback.print_exc()
        return None


async def test_jd():
    print("\n" + "=" * 60)
    print("测试京东联盟 API")
    print("=" * 60)
    
    if not settings.jd_app_key or not settings.jd_app_secret:
        print("❌ 京东 API 密钥未配置")
        return None
    
    try:
        jd_client = RealJDClient()
        
        start_time = time.time()
        products = await jd_client.search(["iPhone"], page_size=10)
        elapsed = time.time() - start_time
        
        print(f"✅ 京东 API 调用成功 (耗时: {elapsed:.2f}秒)")
        print(f"   返回商品数: {len(products)}")
        for p in products[:3]:
            print(f"   - {p['name']} (¥{p['price']})")
        return elapsed
        
    except Exception as e:
        print(f"❌ 京东 API 调用失败: {e}")
        import traceback
        traceback.print_exc()
        return None


async def test_pdd():
    print("\n" + "=" * 60)
    print("测试拼多多联盟 API")
    print("=" * 60)
    
    if not settings.pdd_client_id or not settings.pdd_client_secret:
        print("❌ 拼多多 API 密钥未配置")
        return None
    
    try:
        pdd_client = RealPDDClient()
        
        start_time = time.time()
        products = await pdd_client.search(["iPhone"], page_size=10)
        elapsed = time.time() - start_time
        
        print(f"✅ 拼多多 API 调用成功 (耗时: {elapsed:.2f}秒)")
        print(f"   返回商品数: {len(products)}")
        for p in products[:3]:
            print(f"   - {p['name']} (¥{p['price']})")
        return elapsed
        
    except Exception as e:
        print(f"❌ 拼多多 API 调用失败: {e}")
        import traceback
        traceback.print_exc()
        return None


async def main():
    print("\n" + "=" * 60)
    print("SnapShop API 性能诊断工具")
    print("=" * 60)
    
    results = {}
    
    # 测试各个 API
    results["VLM"] = await test_vlm()
    results["LLM"] = await test_llm()
    results["京东"] = await test_jd()
    results["拼多多"] = await test_pdd()
    
    # 总结
    print("\n" + "=" * 60)
    print("性能总结")
    print("=" * 60)
    
    for name, elapsed in results.items():
        if elapsed:
            status = "✅" if elapsed < 5 else "⚠️"
            print(f"{status} {name}: {elapsed:.2f}秒")
        else:
            print(f"❌ {name}: 测试失败")
    
    total = sum(e for e in results.values() if e)
    print(f"\n📊 总计: {total:.2f}秒")


if __name__ == "__main__":
    asyncio.run(main())
