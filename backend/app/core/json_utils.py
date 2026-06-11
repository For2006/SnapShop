import json
import logging
import re
from typing import Any

logger = logging.getLogger("snapshop")


def robust_parse_json(text: Any, fallback: Any = None) -> Any:
    """
    高度容错的 JSON 解析器，专门处理 LLM 输出的各种不完美格式。
    
    支持处理:
    - 前后有多余 markdown 标记的输出 (```json ... ```)
    - 有多余注释的 JSON
    - 单引号代替双引号
    - 末尾多余逗号
    - 有多余文字包裹但能提取出 {} 或 [] 的内容
    - 其他常见格式瑕疵
    """
    if not isinstance(text, str):
        if isinstance(text, (dict, list)):
            return text
        try:
            return json.loads(text)
        except Exception:
            return fallback
    
    text = text.strip()
    
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    
    patterns_to_try = [
        r'```json\s*([\s\S]*?)\s*```',
        r'```\s*([\s\S]*?)\s*```',
        r'(\{[\s\S]*\})',
        r'(\[[\s\S]*\])',
    ]
    
    for pattern in patterns_to_try:
        match = re.search(pattern, text, re.MULTILINE | re.DOTALL)
        if match:
            candidate = match.group(1).strip()
            result = _try_fix_and_parse(candidate, fallback)
            if result is not fallback:
                logger.debug("[RobustJSON] 通过 pattern 修复成功")
                return result
    
    result = _try_fix_and_parse(text, fallback)
    if result is not fallback:
        return result
    
    logger.warning(f"[RobustJSON] 所有修复方式失败，返回 fallback, raw_text_preview={text[:200]}")
    return fallback


def _try_fix_and_parse(text: str, fallback: Any) -> Any:
    fixes = [
        lambda s: re.sub(r'//.*', '', s),
        lambda s: re.sub(r'/\*[\s\S]*?\*/', '', s),
        lambda s: re.sub(r',\s*([}\]])', r'\1', s),
        lambda s: re.sub(r"'([^'\\]*(\\.[^'\\]*)*)'", lambda m: '"' + m.group(1).replace('"', '\\"') + '"', s),
    ]
    
    current = text
    for fix_fn in fixes:
        try:
            current = fix_fn(current)
            parsed = json.loads(current)
            logger.debug("[RobustJSON] 修复后解析成功")
            return parsed
        except Exception:
            continue
    
    return fallback
