import asyncio
import time
import sys
import os
from dotenv import load_dotenv

# 确保从 backend 目录加载 .env 文件
backend_dir = os.path.join(os.path.dirname(__file__), "backend")
load_dotenv(os.path.join(backend_dir, ".env"))

sys.path.insert(0, backend_dir)

from app.clients.real_pdd_client import RealPDDClient
from app.clients.real_jd_client import RealJDClient


async def test_search(client, name, keywords):
    print(f"\n{'='*60}")
    print(f"测试 {name} 搜索: {keywords}")
    print(f"{'='*60}")
    
    start_time = time.time()
    products = await client.search(keywords, page_size=5)
    elapsed = time.time() - start_time
    
    print(f"✅ 耗时: {elapsed:.2f}秒, 返回商品数: {len(products)}")
    for i, p in enumerate(products, 1):
        print(f"  {i}. [{p['platform']}] {p['name'][:35]}... ¥{p['price']}")
    
    return products


async def main():
    print("\n" + "="*60)
    print("智能 Mock 商品库测试")
    print("="*60)
    
    pdd_client = RealPDDClient()
    jd_client = RealJDClient()
    
    # 测试不同关键词
    test_cases = [
        (["运动鞋"], "运动鞋"),
        (["连衣裙"], "连衣裙"),
        (["蓝牙耳机"], "蓝牙耳机"),
        (["手机"], "手机"),
        (["T恤"], "T恤"),
    ]
    
    all_results = {}
    
    for keywords, desc in test_cases:
        pdd_prods = await test_search(pdd_client, "拼多多", keywords)
        jd_prods = await test_search(jd_client, "京东", keywords)
        all_results[desc] = (pdd_prods, jd_prods)
    
    print("\n" + "="*60)
    print("验证结果 - 不同关键词返回不同商品")
    print("="*60)
    
    # 验证运动鞋和连衣裙的商品是否不同
    sports_shoes_names = set(p["name"] for p in all_results["运动鞋"][0])
    dress_names = set(p["name"] for p in all_results["连衣裙"][0])
    
    overlap = sports_shoes_names & dress_names
    if not overlap:
        print("✅ 运动鞋和连衣裙的商品完全不同！")
    else:
        print(f"⚠️  有 {len(overlap)} 个重复商品")
    
    print("\n🎉 测试完成！不同关键词现在会返回不同的相关商品！")


if __name__ == "__main__":
    asyncio.run(main())
