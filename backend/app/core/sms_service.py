import logging
import random

from app.config import settings
from app.core.cache import get_cache_manager

logger = logging.getLogger("snapshop")

_SMS_CODE_KEY_PREFIX = "sms:code:"
_SMS_COOLDOWN_KEY_PREFIX = "sms:cooldown:"


def _generate_random_6_digit_code() -> str:
    return str(random.randint(100000, 999999))


class AliyunSmsProvider:
    def __init__(self):
        self._enabled = bool(
            settings.aliyun_sms_access_key_id
            and settings.aliyun_sms_access_key_secret
            and settings.aliyun_sms_sign_name
        )

    def is_available(self) -> bool:
        return self._enabled

    async def send_sms(self, phone: str, code: str, scene: str) -> bool:
        if not self._enabled:
            return False
        try:
            import httpx

            template_code = settings.aliyun_sms_login_template_code
            if scene == "change_phone":
                template_code = settings.aliyun_sms_change_phone_template_code

            access_key_id = settings.aliyun_sms_access_key_id
            access_key_secret = settings.aliyun_sms_access_key_secret
            sign_name = settings.aliyun_sms_sign_name

            from alibabacloud_dysmsapi20170525.client import Client as DysmsApiClient
            from alibabacloud_dysmsapi20170525 import models as dysmsapi_20170525_models
            from alibabacloud_tea_openapi import models as open_api_models
            from alibabacloud_tea_util import models as util_models

            config = open_api_models.Config(
                access_key_id=access_key_id,
                access_key_secret=access_key_secret,
            )
            config.endpoint = f"dysmsapi.aliyuncs.com"

            client = DysmsApiClient(config)

            request = dysmsapi_20170525_models.SendSmsRequest(
                sign_name=sign_name,
                phone_numbers=phone,
                template_code=template_code,
                template_param=f'{{"code":"{code}"}}',
            )

            runtime = util_models.RuntimeOptions()
            response = await client.send_sms_async_with_options(request, runtime)

            if response.body.code == "OK":
                logger.info(f"[AliyunSMS] 短信发送成功 phone={phone} BizId={response.body.biz_id}")
                return True
            else:
                logger.error(f"[AliyunSMS] 短信发送失败 phone={phone} Code={response.body.code} Message={response.body.message}")
                return False

        except ImportError:
            logger.warning("[AliyunSMS] 阿里云 SDK 未安装，仅在缓存中存储验证码")
            return False
        except Exception as e:
            logger.error(f"[AliyunSMS] 发送短信异常: {e}")
            return False


class SmsCodeService:
    def __init__(self):
        self._cache_mgr = get_cache_manager()
        self._aliyun_provider = AliyunSmsProvider()

    async def can_send(self, phone: str, scene: str) -> bool:
        cooldown_key = f"{_SMS_COOLDOWN_KEY_PREFIX}{scene}:{phone}"
        return not await self._cache_mgr.exists(cooldown_key)

    async def send(self, phone: str, scene: str) -> str:
        if not await self.can_send(phone, scene):
            logger.warning(f"[SmsService] 冷却中，拒绝发送 phone={phone} scene={scene}")
            raise Exception("SMS code in cooldown, please try later")

        code = _generate_random_6_digit_code()

        code_key = f"{_SMS_CODE_KEY_PREFIX}{scene}:{phone}"
        cooldown_key = f"{_SMS_COOLDOWN_KEY_PREFIX}{scene}:{phone}"

        await self._cache_mgr.set(code_key, code, settings.sms_code_expire_seconds)
        await self._cache_mgr.set(cooldown_key, "1", settings.sms_code_cooldown_seconds)

        logger.info(f"[SmsService] 验证码已生成 phone={phone} scene={scene}")

        if self._aliyun_provider.is_available():
            await self._aliyun_provider.send_sms(phone, code, scene)
        else:
            logger.info(f"[SmsService] 未配置阿里云短信服务，仅在缓存中存储")

        if settings.debug:
            logger.info(f"[SmsService] 开发环境明文返回验证码: {code}")
            return code

        return code

    async def verify(self, phone: str, scene: str, input_code: str) -> bool:
        code_key = f"{_SMS_CODE_KEY_PREFIX}{scene}:{phone}"
        stored_code = await self._cache_mgr.get(code_key)

        if not stored_code:
            logger.warning(f"[SmsService] 验证码不存在或已过期 phone={phone} scene={scene}")
            return False

        if str(stored_code).strip() == str(input_code).strip():
            await self._cache_mgr.delete(code_key)
            logger.info(f"[SmsService] 验证码验证成功 phone={phone} scene={scene}")
            return True

        logger.warning(f"[SmsService] 验证码验证失败 phone={phone} scene={scene}")
        return False


_sms_service_instance: SmsCodeService | None = None


def get_sms_service() -> SmsCodeService:
    global _sms_service_instance
    if _sms_service_instance is None:
        _sms_service_instance = SmsCodeService()
    return _sms_service_instance
