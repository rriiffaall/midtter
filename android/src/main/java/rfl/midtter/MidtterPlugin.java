package rfl.midtter;
import android.util.Log;
import android.content.Context;

import com.google.gson.JsonObject;
import com.midtrans.sdk.corekit.callback.TransactionFinishedCallback;
import com.midtrans.sdk.corekit.core.MidtransSDK;
import com.midtrans.sdk.corekit.core.TransactionRequest;
import com.midtrans.sdk.corekit.core.UIKitCustomSetting;
import com.midtrans.sdk.corekit.core.themes.CustomColorTheme;
import com.midtrans.sdk.corekit.models.CustomerDetails;
import com.midtrans.sdk.corekit.models.ItemDetails;
import com.midtrans.sdk.corekit.models.snap.TransactionResult;
import com.midtrans.sdk.uikit.SdkUIFlowBuilder;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** MidtterPlugin */
public class MidtterPlugin implements MethodCallHandler {
  static final String TAG = "MidtterPlugin";
  private final Registrar registrar;
  private final MethodChannel channel;
  private Context context;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "midtter");
    channel.setMethodCallHandler(new MidtterPlugin(registrar, channel));
  }

  private MidtterPlugin(Registrar registrar, MethodChannel channel) {
    this.registrar = registrar;
    this.channel = channel;
    this.context = registrar.activeContext();
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if(call.method.equals("init")) {
      initMidtransSdk((String)call.argument("client_key").toString(), call.argument("base_url").toString());
    } else if(call.method.equals("payment")) {
      String str = call.arguments();
      payment(str);
    } else {
      result.notImplemented();
    }
  }

  private void initMidtransSdk(String client_key, String base_url) {
    SdkUIFlowBuilder.init()
            .setClientKey(client_key) // client_key is mandatory
            .setContext(context) // context is mandatory
            .setTransactionFinishedCallback(new TransactionFinishedCallback(){
                @Override
                public void onTransactionFinished(TransactionResult transactionResult) {
                    Map<String, Object> content = new HashMap<>();
                    content.put("transactionCanceled", transactionResult.isTransactionCanceled());
                    content.put("status", transactionResult.getStatus());
                    content.put("source", transactionResult.getSource());
                    content.put("statusMessage", transactionResult.getStatusMessage());
                    if(transactionResult.getResponse() != null)
                        content.put("response", transactionResult.getResponse().toString());
                    else
                        content.put("response", null);
                    channel.invokeMethod("onTransactionFinished", content);
                }
            }) // set transaction finish callback (sdk callback)
            .setMerchantBaseUrl(base_url) //set merchant url
            .enableLog(true) // enable sdk log
            //.setColorTheme(new CustomColorTheme("#4CAF50", "#009688", "#CDDC39")) // will replace theme on snap theme on MAP
            .buildSDK();
  }

  void payment(String str) {
    try {
      Log.d(TAG, str);
      JSONObject json = new JSONObject(str);
      JSONObject cJson = json.getJSONObject("customer");
      TransactionRequest transactionRequest = new
              TransactionRequest(json.getString("order_id") + "", json.getInt("total"));
      ArrayList<ItemDetails> itemList = new ArrayList<>();
      JSONArray arr = json.getJSONArray("items");
      for(int i = 0; i < arr.length(); i++) {
        JSONObject obj = arr.getJSONObject(i);
        ItemDetails item = new ItemDetails(obj.getString("id"), obj.getInt("price"), obj.getInt("quantity"), obj.getString("name"));
        itemList.add(item);
      }
      CustomerDetails cus = new CustomerDetails();
      cus.setFirstName(cJson.getString("first_name"));
      cus.setLastName(cJson.getString("last_name"));
      cus.setEmail(cJson.getString("email"));
      cus.setPhone(cJson.getString("phone"));
      transactionRequest.setCustomerDetails(cus);
      if(json.has("custom_field_1"))
        transactionRequest.setCustomField1(json.getString("custom_field_1"));
      transactionRequest.setItemDetails(itemList);
      UIKitCustomSetting setting = MidtransSDK.getInstance().getUIKitCustomSetting();
      if(json.has("skip_customer"))
        setting.setSkipCustomerDetailsPages(json.getBoolean("skip_customer"));
      MidtransSDK.getInstance().setUIKitCustomSetting(setting);
      MidtransSDK.getInstance().setTransactionRequest(transactionRequest);
      MidtransSDK.getInstance().startPaymentUiFlow(context);
    } catch(Exception e) {
      Log.d(TAG, "ERROR " + e.getMessage());
    }
  }
}
