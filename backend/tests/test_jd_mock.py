import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.clients.jd_mock_database import JDMockDatabase


def test_jd_mock_database():
    print("=" * 60)
    print("开始测试 JD Mock 数据库...")
    print("=" * 60)

    db = JDMockDatabase()

    stats = db.get_statistics()
    print("\n数据库统计信息:")
    print(f"  总商品数: {stats['total_products']}")
    print(f"  京东自营商品数: {stats['self_operated_count']}")
    print(f"  京东物流商品数: {stats['jd_logistics_count']}")
    print("  分类分布:")
    for cat, count in stats["category_distribution"].items():
        print(f"    - {cat}: {count} 件")

    assert stats["total_products"] == 500, f"期望500件商品，实际{stats['total_products']}件"
    print("\n✓ 商品总数验证通过: 500件")

    print("\n测试关键词搜索...")
    results = db.search_by_keywords(["手机"], limit=5)
    print(f"  搜索'手机'返回 {len(results)} 条结果")
    for i, p in enumerate(results[:3], 1):
        print(f"    {i}. {p['title']} - ¥{p['price']}")
        print(f"       URL: {p['product_url']}")
        print(f"       标签: {p['tags']}")
    assert len(results) > 0, "搜索手机应该返回结果"
    print("✓ 关键词搜索验证通过")

    print("\n测试按分类获取商品...")
    phones = db.get_products_by_category("手机", limit=3)
    print(f"  获取'手机'分类商品 {len(phones)} 件")
    for p in phones[:2]:
        assert p["category"] == "手机", "分类应该是手机"
    print("✓ 按分类获取验证通过")

    print("\n测试商品ID格式...")
    sample_product = list(db.products.values())[0]
    assert sample_product.product_url.startswith("https://item.jd.com/"), "URL格式错误"
    assert sample_product.product_url.endswith(".html"), "URL格式错误"
    print(f"  示例商品URL: {sample_product.product_url}")
    print("✓ 京东链接格式验证通过")

    print("\n测试京东专属标签...")
    has_self_operated = any("京东自营" in p.tags for p in db.products.values())
    has_jd_logistics = any("京东物流" in p.tags for p in db.products.values())
    assert has_self_operated, "应该有京东自营标签的商品"
    assert has_jd_logistics, "应该有京东物流标签的商品"
    print("✓ 京东专属标签验证通过")

    print("\n" + "=" * 60)
    print("所有测试通过! JD Mock 数据库运行正常。")
    print("=" * 60)


if __name__ == "__main__":
    test_jd_mock_database()
