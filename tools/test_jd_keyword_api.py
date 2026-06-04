import asyncio
import sys
import os
from dotenv import load_dotenv

# 确保从 backend 目录加载 .env 文件
backend_dir = os.path.join(os.path.dirname(__file__), "backend")
load_dotenv(os.path.join(backend_dir, ".env"))

sys.path.insert(0, backend_dir)

from app.clients.real_jd_client import RealJDClient
from app.config import settings


async def test_jd_keyword_api():
    print("=" * 60)
    print("京东联盟关键词搜索接口测试")
    print("=" * 60)
    
    print(f"\n当前配置状态:")
    print(f"  jd_app_key: {'已配置' if settings.jd_app_key else '未配置'}")
    print(f"  jd_app_secret: {'已配置' if settings.jd_app_secret else '未配置'}")
    print(f"  jd_api_url: {settings.jd_api_url}")
    
    if not settings.jd_app_key or not settings.jd_app_secret:
        print("\n⚠️  警告: 京东联盟 API 凭证未配置!")
        print("请在 backend/.env 文件中配置以下参数:")
        print("  jd_app_key=你的京东联盟app_key")
        print("  jd_app_secret=你的京东联盟app_secret")
        return
    
    print("\n开始测试关键词搜索接口...")
    
    client = RealJDClient()
    
    try:
        print("\n1. 测试 _fetch_goods_by_keyword 方法...")
        goods_list = await client._fetch_goods_by_keyword("手机", page_size=5)
        print(f"   ✅ 成功! 获取到 {len(goods_list)} 个商品")
        
        if goods_list:
            print("\n   前3个商品示例:")
            for i, goods in enumerate(goods_list[:3], 1):
                print(f"   {i}. SKU: {goods.get('skuName', 'N/A')[:50]}...")
                print(f"      价格: {goods.get('priceInfo', {}).get('price', 'N/A')}")
        
        print("\n2. 测试完整 search 方法...")
        results = await client.search(["手机"], page_size=5)
        print(f"   ✅ 成功! 返回 {len(results)} 个处理后的商品")
        
        if results:
            print("\n   前3个结果示例:")
            for i, product in enumerate(results[:3], 1):
                print(f"   {i}. {product['name'][:50]}...")
                print(f"      价格: ¥{product['price']}")
        
        print("\n" + "=" * 60)
        print("✅ 所有测试通过! 关键词搜索API工作正常!")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n❌ 测试失败: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
    finally:
        await client.close()


if __name__ == "__main__":
    asyncio.run(test_jd_keyword_api())
