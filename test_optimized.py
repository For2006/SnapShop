import asyncio
import time
import sys
import os
from dotenv import load_dotenv

# 确保从 backend 目录加载 .env 文件
backend_dir = os.path.join(os.path.dirname(__file__), "backend")
load_dotenv(os.path.join(backend_dir, ".env"))

sys.path.insert(0, backend_dir)

from app.services.text_search_service import TextSearchService
from app.core.database import async_session


async def test_full_search():
    print("\n" + "=" * 60)
    print("测试完整搜索流程")
    print("=" * 60)
    
    try:
        service = TextSearchService()
        
        start_time = time.time()
        
        async with async_session() as db:
            result = await service.search(
                keywords=["运动鞋"],
                device_id="test-device",
                db=db
            )
        
        elapsed = time.time() - start_time
        
        print(f"✅ 完整搜索调用成功 (耗时: {elapsed:.2f}秒)")
        print(f"   找到商品: {len(result['products'])} 个")
        print(f"   建议卡片: {len(result['suggestions'])} 个")
        
        for p in result['products'][:3]:
            print(f"   - {p['name']} (¥{p['price']})")
            
        return elapsed
        
    except Exception as e:
        print(f"❌ 完整搜索调用失败: {e}")
        import traceback
        traceback.print_exc()
        return None


async def main():
    print("\n" + "=" * 60)
    print("SnapShop 优化后性能测试")
    print("=" * 60)
    
    # 测试完整搜索
    full_search_time = await test_full_search()
    
    # 总结
    print("\n" + "=" * 60)
    print("性能优化总结")
    print("=" * 60)
    if full_search_time:
        status = "✅ 显著提升!" if full_search_time < 5 else "⚠️ 可以进一步优化"
        print(f"{status} 完整搜索流程耗时: {full_search_time:.2f}秒")
        print("\n优化措施:")
        print("  • 移除了缓慢的 LLM 建议卡片生成")
        print("  • 移除了缓慢的 LLM 关键词扩展")
        print("  • 降低了 API 超时时间 (60s→15s)")
        print("  • 减少了重试次数 (3→1)")
        print("  • 降低了 page_size (50→20)")
        print("  • 添加了性能监控中间件")


if __name__ == "__main__":
    asyncio.run(main())
