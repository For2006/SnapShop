import asyncio
import sys
import os
import json
import hashlib
import time
from dotenv import load_dotenv

backend_dir = os.path.join(os.path.dirname(__file__), "backend")
load_dotenv(os.path.join(backend_dir, ".env"))

sys.path.insert(0, backend_dir)

import httpx
from app.config import settings


async def debug_jd_search():
    print("=" * 70)
    print("京东联盟 jd.union.open.goods.search 接口调试")
    print("=" * 70)
    
    app_key = settings.jd_app_key
    app_secret = settings.jd_app_secret
    api_url = settings.jd_api_url
    
    print(f"\n配置信息:")
    print(f"  app_key: {app_key[:10]}..." if app_key else "  app_key: 未配置")
    print(f"  api_url: {api_url}")
    
    if not app_key or not app_secret:
        print("\n❌ 凭证未配置!")
        return
    
    # 尝试多种参数结构
    test_cases = [
        {
            "name": "结构1: goodsReqDTO 包装",
            "biz_params": {
                "goodsReqDTO": {
                    "keyword": "手机",
                    "pageIndex": 1,
                    "pageSize": 10,
                }
            }
        },
        {
            "name": "结构2: 直接参数",
            "biz_params": {
                "keyword": "手机",
                "pageIndex": 1,
                "pageSize": 10,
            }
        },
        {
            "name": "结构3: 360buy_param_json",
            "use_360buy": True,
            "biz_params": {
                "keyword": "手机",
                "pageIndex": 1,
                "pageSize": 10,
            }
        },
    ]
    
    for test in test_cases:
        print(f"\n{'='*70}")
        print(f"测试: {test['name']}")
        print(f"{'='*70}")
        
        biz_params = test["biz_params"]
        param_key = "360buy_param_json" if test.get("use_360buy") else "param_json"
        
        request_params = {
            "method": "jd.union.open.goods.search",
            "app_key": app_key,
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),
            "format": "json",
            "v": "1.0",
            "sign_method": "md5",
            param_key: json.dumps(biz_params, ensure_ascii=False),
        }
        
        # 生成签名
        ordered = sorted(request_params.items(), key=lambda x: x[0])
        raw = "".join(f"{k}{v}" for k, v in ordered)
        raw = app_secret + raw + app_secret
        sign = hashlib.md5(raw.encode("utf-8")).hexdigest().upper()
        request_params["sign"] = sign
        
        print(f"\n请求参数:")
        print(json.dumps(request_params, ensure_ascii=False, indent=2))
        
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                resp = await client.get(api_url, params=request_params)
                print(f"\n响应状态码: {resp.status_code}")
                print(f"\n完整响应内容:")
                print(json.dumps(resp.json(), ensure_ascii=False, indent=2))
                
                result_json = resp.json()
                
                # 尝试解析各种可能的响应结构
                possible_keys = [
                    "jd_union_open_goods_search_response",
                    "jdUnionOpenGoodsSearchResponse",
                    "result",
                    "data",
                ]
                
                for key in possible_keys:
                    if key in result_json:
                        print(f"\n✅ 找到响应根节点: {key}")
                        break
                
        except Exception as e:
            print(f"\n❌ 请求失败: {type(e).__name__}: {e}")
            import traceback
            traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(debug_jd_search())
