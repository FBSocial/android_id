import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { identifier } from '@kit.AdsKit';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  AbilityPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import { deviceInfo } from '@kit.BasicServicesKit';

/** AndroidIdPlugin **/
export default class AndroidIdPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;

  private context: common.Context | null = null;

  constructor() {
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "android_id");
    this.channel.setMethodCallHandler(this)
  }

  getUniqueClassName(): string {
    return "AndroidIdPlugin"
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "getId") {
      this.getOAID(result);
    } else {
      result.notImplemented()
    }
  }

  async getOAID(result: MethodResult){
    // 进入页面时触发动态授权弹框，向用户请求授权广告跟踪权限
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    //策略： 优先申请权限拿oaid (IDFA),  拿不到就拿odid (IDFV)
    let odid: string = deviceInfo.ODID;
    try {
      atManager.requestPermissionsFromUser(this.context, ["ohos.permission.APP_TRACKING_CONSENT"]).then((data) => {
        if (data.authResults[0] == 0) {
          hilog.info(0x0000, 'testTag', '%{public}s', 'succeeded in requesting permission');
          identifier.getOAID((err: BusinessError, data: string) => {
            if (err.code) {
              result.success(odid);
            } else {
              const oaid: string = data;
              result.success(oaid);
            }
          });
        } else {
          hilog.error(0x0000, 'testTag', '%{public}s', 'user rejected');
          result.success(odid);
        }
      }).catch((err: BusinessError) => {
        result.success(odid);
      })
    } catch (err) {
      result.success(odid);
    }
  }
}