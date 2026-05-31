import asyncio
import time
import sys
import os
from dotenv import load_dotenv

backend_dir = os.path.join(os.path.dirname(__file__), "backend")
load_dotenv(os.path.join(backend_dir, ".env"))
sys.path.insert(0, backend_dir)

from app.services.recognition_service import RecognitionService
from app.services.text_search_service import TextSearchService
from app.core.database import async_session


async def test_recognition():
    print("\n" + "=" * 70)
    print("📸 拍照识别功能测试")
    print("=" * 70)
    
    service = RecognitionService()
    
    # 创建一个简单的测试图片
    test_image = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xff\xdb\x00C\x00\x03\x02\x02\x02\x02\x02\x03\x02\x02\x02\x03\x03\x03\x03\x04\x06\x04\x04\x04\x04\x04\x08\x06\x06\x05\x06\x09\x08\x0a\x0a\x09\x08\x09\x09\x0a\x0c\x0f\x0c\x0a\x0b\x0e\x0b\x09\x09\x0d\x11\x0d\x0e\x0f\x10\x10\x11\x10\x0a\x0c\x12\x13\x12\x10\x13\x0f\x10\x10\x10\xff\xc0\x00\x0b\x08\x00\x01\x00\x01\x01\x01\x11\x00\xff\xc4\x00\x14\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\xff\xc4\x00\x14\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xda\x00\x08\x01\x01\x00\x00?\x00T\x9f\xff\xd9"
    
    start_time = time.time()
    
    try:
        async with async_session() as db:
            result = await service.recognize(test_image, device_id="test-device-001", db=db)
        
        elapsed = time.time() - start_time
        
        print(f"✅ 拍照识别成功! 总耗时: {elapsed:.2f}秒")
        print(f"   Session ID: {result.get('session_id', 'N/A')}")
        
        recognition = result.get('recognition', {})
        print(f"\n🏷️  识别结果:")
        print(f"   分类: {recognition.get('category', 'N/A')}")
        
        attributes = recognition.get('attributes', [])
        print(f"   属性数量: {len(attributes)}")
        for attr in attributes[:5]:
            print(f"     - {attr.get('label')}: {attr.get('value')} (置信度: {attr.get('confidence')})")
        
        suggestions = recognition.get('suggestions', [])
        print(f"\n💡 建议卡片数量: {len(suggestions)}")
        for s in suggestions[:3]:
            print(f"     - {s.get('title')}")
        
        products = result.get('products', [])
        print(f"\n🛍️  返回商品数量: {len(products)}")
        
        # 商品完整性检查
        print(f"\n📊 商品完整性检查:")
        all_valid = True
        for i, p in enumerate(products[:5], 1):
            product_id = p.get('id', '')
            name = p.get('name', '')
            price = p.get('price', 0)
            platform = p.get('platform', '')
            product_url = p.get('product_url', '')
            
            valid = bool(product_id and name and price > 0 and platform and product_url)
            status = "✅" if valid else "❌"
            print(f"   {status} 商品{i}: ID={bool(product_id)}, 名称={bool(name)}, 价格={price>0}, 平台={bool(platform)}, 链接={bool(product_url)}")
            
            if not valid:
                all_valid = False
        
        if all_valid and len(products) > 0:
            print(f"\n🎉 所有商品字段完整!")
        else:
            print(f"\n⚠️  部分商品字段缺失!")
        
        return {
            "success": True,
            "elapsed": elapsed,
            "products_count": len(products),
            "category": recognition.get('category', ''),
            "all_valid": all_valid,
        }
        
    except Exception as e:
        elapsed = time.time() - start_time
        print(f"❌ 拍照识别失败! 耗时: {elapsed:.2f}秒")
        print(f"   错误: {e}")
        import traceback
        traceback.print_exc()
        return {
            "success": False,
            "elapsed": elapsed,
            "error": str(e),
        }


async def test_text_search():
    print("\n" + "=" * 70)
    print("🔍 文字识别/搜索功能测试")
    print("=" * 70)
    
    service = TextSearchService()
    
    test_keywords_list = [
        ["运动鞋"],
        ["连衣裙"],
        ["蓝牙耳机"],
    ]
    
    results = []
    
    for keywords in test_keywords_list:
        print(f"\n--- 测试关键词: {keywords[0]} ---")
        start_time = time.time()
        
        try:
            async with async_session() as db:
                result = await service.search(keywords, device_id="test-device-002", db=db)
            
            elapsed = time.time() - start_time
            
            products = result.get('products', [])
            suggestions = result.get('suggestions', [])
            
            print(f"✅ 搜索成功! 耗时: {elapsed:.2f}秒")
            print(f"   商品数量: {len(products)}")
            print(f"   建议卡片: {len(suggestions)}")
            
            # 商品完整性检查
            all_valid = True
            for i, p in enumerate(products[:3], 1):
                product_id = p.get('id', '')
                name = p.get('name', '')
                price = p.get('price', 0)
                platform = p.get('platform', '')
                product_url = p.get('product_url', '')
                
                valid = bool(product_id and name and price > 0 and platform and product_url)
                status = "✅" if valid else "❌"
                print(f"   {status} 商品{i}: [{p.get('platform').upper()}] {p.get('name')[:30]}... ¥{p.get('price')}")
                
                if not valid:
                    all_valid = False
            
            results.append({
                "keywords": keywords[0],
                "success": True,
                "elapsed": elapsed,
                "products_count": len(products),
                "all_valid": all_valid,
            })
            
        except Exception as e:
            elapsed = time.time() - start_time
            print(f"❌ 搜索失败! 耗时: {elapsed:.2f}秒")
            print(f"   错误: {e}")
            import traceback
            traceback.print_exc()
            
            results.append({
                "keywords": keywords[0],
                "success": False,
                "elapsed": elapsed,
                "error": str(e),
            })
    
    return results


async def main():
    print("\n" + "=" * 70)
    print("SnapShop 完整功能诊断测试")
    print("=" * 70)
    
    # 测试拍照识别
    recog_result = await test_recognition()
    
    # 测试文字搜索
    text_results = await test_text_search()
    
    # 生成总结报告
    print("\n" + "=" * 70)
    print("📊 性能总结报告")
    print("=" * 70)
    
    print("\n📸 拍照识别:")
    if recog_result.get('success'):
        elapsed = recog_result.get('elapsed', 0)
        status = "✅ 正常" if elapsed < 10 else "⚠️  偏慢" if elapsed < 20 else "❌ 很慢"
        print(f"   状态: {status}")
        print(f"   耗时: {elapsed:.2f}秒")
        print(f"   商品数: {recog_result.get('products_count', 0)}")
        print(f"   商品完整: {'是' if recog_result.get('all_valid') else '否'}")
    else:
        print(f"   状态: ❌ 失败")
        print(f"   错误: {recog_result.get('error')}")
    
    print("\n🔍 文字搜索:")
    total_text_time = 0
    all_text_ok = True
    for r in text_results:
        kw = r.get('keywords', '')
        if r.get('success'):
            elapsed = r.get('elapsed', 0)
            total_text_time += elapsed
            status = "✅" if elapsed < 5 else "⚠️" if elapsed < 10 else "❌"
            print(f"   {status} {kw}: {elapsed:.2f}秒, 商品{r.get('products_count', 0)}个")
            if not r.get('all_valid'):
                all_text_ok = False
        else:
            print(f"   ❌ {kw}: 失败 - {r.get('error')}")
            all_text_ok = False
    
    avg_text_time = total_text_time / len(text_results) if text_results else 0
    print(f"\n   平均耗时: {avg_text_time:.2f}秒")
    print(f"   商品完整: {'全部是' if all_text_ok else '部分缺失'}")
    
    print("\n" + "=" * 70)
    print("🎉 诊断测试完成!")
    print("=" * 70)


if __name__ == "__main__":
    asyncio.run(main())
