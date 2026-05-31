import asyncio
import sys
import os
from dotenv import load_dotenv

backend_dir = os.path.join(os.path.dirname(__file__), "backend")
load_dotenv(os.path.join(backend_dir, ".env"))
sys.path.insert(0, backend_dir)

from app.clients.mock_product_generator import MockProductGenerator


def test_generator():
    print("\n" + "=" * 70)
    print("强大 Mock 商品生成器测试 - 京东 & 拼多多各 500 条")
    print("=" * 70)
    
    generator = MockProductGenerator()
    
    # 测试京东 500 条
    print("\n📦 正在生成京东 500 条商品...")
    jd_products = generator.generate_jd_products(500)
    print(f"✅ 京东商品生成成功: {len(jd_products)} 条")
    
    # 测试拼多多 500 条
    print("\n📦 正在生成拼多多 500 条商品...")
    pdd_products = generator.generate_pdd_products(500)
    print(f"✅ 拼多多商品生成成功: {len(pdd_products)} 条")
    
    # 统计分析
    print("\n" + "=" * 70)
    print("📊 商品统计分析")
    print("=" * 70)
    
    jd_categories = {}
    pdd_categories = {}
    
    for p in jd_products:
        cat = p["attributes"]["category"]
        jd_categories[cat] = jd_categories.get(cat, 0) + 1
    
    for p in pdd_products:
        cat = p["attributes"]["category"]
        pdd_categories[cat] = pdd_categories.get(cat, 0) + 1
    
    print("\n🏷️  京东商品分类分布:")
    for cat, count in sorted(jd_categories.items(), key=lambda x: -x[1]):
        print(f"   - {cat:<12} : {count:>3} 条")
    
    print("\n🏷️  拼多多商品分类分布:")
    for cat, count in sorted(pdd_categories.items(), key=lambda x: -x[1]):
        print(f"   - {cat:<12} : {count:>3} 条")
    
    # 样本展示
    print("\n" + "=" * 70)
    print("🎁 京东商品样本 (前5条)")
    print("=" * 70)
    for i, p in enumerate(jd_products[:5], 1):
        print(f"\n{i}. [{p['platform'].upper()}] {p['name'][:50]}...")
        print(f"   价格: ¥{p['price']:.2f} | 店铺: {p['shop_name']}")
        print(f"   链接: {p['product_url']}")
        print(f"   标签: {', '.join(p['tags'])}")
    
    print("\n" + "=" * 70)
    print("🎁 拼多多商品样本 (前5条)")
    print("=" * 70)
    for i, p in enumerate(pdd_products[:5], 1):
        print(f"\n{i}. [{p['platform'].upper()}] {p['name'][:50]}...")
        print(f"   价格: ¥{p['price']:.2f} | 店铺: {p['shop_name']}")
        print(f"   链接: {p['product_url']}")
        print(f"   标签: {', '.join(p['tags'])}")
    
    # 测试关键词搜索
    print("\n" + "=" * 70)
    print("🔍 关键词搜索测试")
    print("=" * 70)
    
    test_keywords_list = [
        ["运动鞋"],
        ["连衣裙"],
        ["蓝牙耳机"],
        ["手机"],
        ["笔记本电脑"],
    ]
    
    for keywords in test_keywords_list:
        jd_result = generator.get_products_by_keywords(keywords, "jd", 3)
        pdd_result = generator.get_products_by_keywords(keywords, "pdd", 3)
        print(f"\n关键词: {keywords[0]}")
        print(f"   京东: {jd_result[0]['name'][:40]}...")
        print(f"   拼多多: {pdd_result[0]['name'][:40]}...")
    
    print("\n" + "=" * 70)
    total = len(jd_products) + len(pdd_products)
    print(f"🎉 总计生成 {total} 条商品 (京东500 + 拼多多500)")
    print("=" * 70)


if __name__ == "__main__":
    test_generator()
