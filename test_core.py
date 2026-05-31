import asyncio
import time
import sys
import os
from dotenv import load_dotenv

# 确保从 backend 目录加载 .env 文件
backend_dir = os.path.join(os.path.dirname(__file__), "backend")
load_dotenv(os.path.join(backend_dir, ".env"))

sys.path.insert(0, backend_dir)

from app.services.search_service import SearchService
from app.services.comparison_service import ComparisonService
from app.services.suggestion_service import SuggestionService


async def test_search_flow():
    print("\n" + "=" * 60)
    print("测试核心搜索流程（无数据库）")
    print("=" * 60)
    
    try:
        # 1. 电商 API 搜索
        print("\n1. 电商 API 搜索...")
        search_service = SearchService()
        start_time = time.time()
        products = await search_service.search_all(keywords=["运动鞋"])
        search_time = time.time() - start_time
        print(f"   ✅ 电商搜索完成 (耗时: {search_time:.2f}秒, 商品数: {len(products)})")
        
        # 2. 商品比较与重排
        print("\n2. 商品比较与重排...")
        start_time = time.time()
        comparison_service = ComparisonService()
        filtered_products, price_summary = comparison_service.compare_and_rerank(products, ["运动鞋"])
        compare_time = time.time() - start_time
        print(f"   ✅ 比较与重排完成 (耗时: {compare_time:.2f}秒, 过滤后商品数: {len(filtered_products)})")
        
        # 3. 建议卡片生成
        print("\n3. 建议卡片生成...")
        start_time = time.time()
        suggestion_service = SuggestionService()
        recall_stats = {
            "total_count": len(filtered_products),
            "category": "运动鞋",
            "platforms": {
                p["platform"]: {
                    "min_price": min(p["price"] for p in filtered_products if p["platform"] == "pdd"),
                    "count": sum(1 for p in filtered_products if p["platform"] == "pdd")
                }
                for p in filtered_products
            }
        }
        suggestions = await suggestion_service.generate({}, recall_stats)
        suggestion_time = time.time() - start_time
        print(f"   ✅ 建议卡片生成完成 (耗时: {suggestion_time:.2f}秒, 卡片数: {len(suggestions)})")
        
        total_time = search_time + compare_time + suggestion_time
        print("\n" + "=" * 60)
        print("性能测试结果")
        print("=" * 60)
        print(f"🔍 电商 API 搜索:    {search_time:>6.2f}秒")
        print(f"⚖️  比较与重排:      {compare_time:>6.2f}秒")
        print(f"💡 建议卡片生成:    {suggestion_time:>6.2f}秒")
        print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"✅ 总计:           {total_time:>6.2f}秒")
        
        print("\n商品预览:")
        for p in filtered_products[:3]:
            print(f"  - {p['name'][:40]}... (¥{p['price']})")
        
        print("\n建议卡片:")
        for s in suggestions:
            print(f"  - {s['title']}")
            
        return total_time
        
    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        return None


async def main():
    print("\n" + "=" * 60)
    print("SnapShop 优化后性能测试")
    print("=" * 60)
    
    # 测试核心搜索流程
    total_time = await test_search_flow()
    
    print("\n" + "=" * 60)
    print("性能优化总结")
    print("=" * 60)
    if total_time:
        status = "✅ 显著提升!" if total_time < 5 else "⚠️ 可以进一步优化"
        print(f"{status} 核心搜索流程耗时: {total_time:.2f}秒")
        print("\n已应用的优化措施:")
        print("  • 移除了缓慢的 LLM 建议卡片生成")
        print("  • 移除了缓慢的 LLM 关键词扩展")
        print("  • 降低了 API 超时时间 (60s→15s)")
        print("  • 减少了重试次数 (3→1)")
        print("  • 降低了 page_size (50→20)")
        print("  • 添加了性能监控中间件")


if __name__ == "__main__":
    asyncio.run(main())
