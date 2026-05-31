import asyncio
import time
import sys
import os
from dotenv import load_dotenv

backend_dir = os.path.join(os.path.dirname(__file__), "backend")
load_dotenv(os.path.join(backend_dir, ".env"))
sys.path.insert(0, backend_dir)

from app.services.search_service import SearchService
from app.services.comparison_service import ComparisonService
from app.services.suggestion_service import SuggestionService


async def test_core_search_flow():
    print("\n" + "=" * 70)
    print("🔍 核心搜索流程诊断（无数据库依赖）")
    print("=" * 70)
    
    test_keywords_list = [
        ["运动鞋"],
        ["连衣裙"],
        ["蓝牙耳机"],
    ]
    
    total_search_time = 0
    all_products_valid = True
    
    for keywords in test_keywords_list:
        print(f"\n--- 测试关键词: {keywords[0]} ---")
        start_time = time.time()
        
        try:
            # 1. 电商 API 搜索
            print("1. 电商 API 搜索...")
            search_service = SearchService()
            products = await search_service.search_all(keywords)
            search_time = time.time() - start_time
            print(f"   ✅ 电商搜索完成 (耗时: {search_time:.2f}秒, 商品数: {len(products)})")
            
            # 2. 商品比较与重排
            print("2. 商品比较与重排...")
            comparison_service = ComparisonService()
            filtered_products, price_summary = comparison_service.compare_and_rerank(products, keywords)
            compare_time = time.time() - start_time - search_time
            print(f"   ✅ 比较与重排完成 (耗时: {compare_time:.2f}秒, 过滤后商品数: {len(filtered_products)})")
            
            # 3. 建议卡片生成
            print("3. 建议卡片生成...")
            suggestion_service = SuggestionService()
            recall_stats = {
                "total_count": len(filtered_products),
                "category": keywords[0],
                "platforms": {
                    p["platform"]: {
                        "min_price": min(p["price"] for p in filtered_products if p["platform"] == p["platform"]),
                        "count": sum(1 for p in filtered_products if p["platform"] == p["platform"])
                    }
                    for p in filtered_products
                }
            }
            suggestions = await suggestion_service.generate({}, recall_stats)
            suggestion_time = time.time() - start_time - search_time - compare_time
            print(f"   ✅ 建议卡片生成完成 (耗时: {suggestion_time:.2f}秒, 卡片数: {len(suggestions)})")
            
            total_time = time.time() - start_time
            total_search_time += total_time
            
            # 商品完整性检查
            print("\n📊 商品完整性检查:")
            for i, p in enumerate(filtered_products[:5], 1):
                product_id = p.get('id', '')
                name = p.get('name', '')
                price = p.get('price', 0)
                platform = p.get('platform', '')
                product_url = p.get('product_url', '')
                
                valid = bool(product_id and name and price > 0 and platform and product_url)
                status = "✅" if valid else "❌"
                print(f"   {status} 商品{i}: ID={bool(product_id)}, 名称={bool(name)}, 价格={price>0}, 平台={bool(platform)}, 链接={bool(product_url)}")
                
                if not valid:
                    all_products_valid = False
            
            # 样本展示
            print("\n🎁 商品样本:")
            for p in filtered_products[:3]:
                print(f"   - [{p['platform'].upper()}] {p['name'][:40]}... ¥{p['price']}")
            
        except Exception as e:
            total_time = time.time() - start_time
            print(f"   ❌ 失败! 耗时: {total_time:.2f}秒")
            print(f"   错误: {e}")
            import traceback
            traceback.print_exc()
    
    # 总结
    print("\n" + "=" * 70)
    print("📊 性能总结报告")
    print("=" * 70)
    
    avg_time = total_search_time / len(test_keywords_list) if test_keywords_list else 0
    status = "✅ 正常" if avg_time < 5 else "⚠️  偏慢" if avg_time < 10 else "❌ 很慢"
    
    print(f"\n🔍 平均搜索耗时: {avg_time:.2f}秒 [{status}]")
    print(f"📦 商品完整性: {'全部完整' if all_products_valid else '部分缺失'}")
    
    print("\n" + "=" * 70)
    print("🎉 诊断测试完成!")
    print("=" * 70)


if __name__ == "__main__":
    asyncio.run(test_core_search_flow())
