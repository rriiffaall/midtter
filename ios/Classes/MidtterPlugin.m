#import <MidtransKit/MidtransKit.h>
#import "MidtterPlugin.h"

FlutterMethodChannel* channel;

@interface MidtterPayment : NSObject<MidtransUIPaymentViewControllerDelegate> {
}
@end

@implementation MidtterPayment
- (void)paymentViewController:(MidtransUIPaymentViewController *)viewController saveCard:(MidtransMaskedCreditCard *)result {
}
- (void)paymentViewController:(MidtransUIPaymentViewController *)viewController saveCardFailed:(NSError *)error {
}
- (void)paymentViewController:(MidtransUIPaymentViewController *)viewController paymentPending:(MidtransTransactionResult *)result {
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];
    [ret setObject:@NO forKey:@"transactionCanceled"];
    [ret setObject:@"pending" forKey:@"status"];
    [channel invokeMethod:@"onTransactionFinished" arguments:ret];
}
- (void)paymentViewController:(MidtransUIPaymentViewController *)viewController paymentSuccess:(MidtransTransactionResult *)result {
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];
    [ret setObject:@NO forKey:@"transactionCanceled"];
    [ret setObject:@"success" forKey:@"status"];
    [channel invokeMethod:@"onTransactionFinished" arguments:ret];
}
- (void)paymentViewController:(MidtransUIPaymentViewController *)viewController paymentFailed:(NSError *)error {
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];
    [ret setObject:@NO forKey:@"transactionCanceled"];
    [channel invokeMethod:@"onTransactionFinished" arguments:ret];
}
- (void)paymentViewController_paymentCanceled:(MidtransUIPaymentViewController *)viewController {
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];
    [ret setObject:@YES forKey:@"transactionCanceled"];
    [channel invokeMethod:@"onTransactionFinished" arguments:ret];
}
@end

@implementation MidtterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  channel = [FlutterMethodChannel
      methodChannelWithName:@"midtter"
            binaryMessenger:[registrar messenger]];
  MidtterPlugin* instance = [[MidtterPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if([@"init" isEqualToString:call.method ]) {
      NSString *key = call.arguments[@"client_key"];
      NSString *url = call.arguments[@"base_url"];
      NSString *env = call.arguments[@"env"];
      MidtransServerEnvironment serverEnvirontment = MidtransServerEnvironmentProduction;
      if([@"sandbox" isEqualToString:env])
          serverEnvirontment = MidtransServerEnvironmentSandbox;
      [CONFIG setClientKey:key environment:serverEnvirontment merchantServerURL:url];
      return result(0);
  } else if([@"payment" isEqualToString:call.method]) {
      NSString *str = call.arguments;
      id delegate = [MidtterPayment alloc];
      NSError *error = nil;
      id object = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:true] options:0 error:&error];
      if([object isKindOfClass:[NSDictionary class]]) {
          NSDictionary *json = object;
          NSDictionary *customer = json[@"customer"];
          MidtransAddress *address = [MidtransAddress addressWithFirstName:customer[@"first_name"] lastName:customer[@"first_name"] phone:customer[@"phone"] address:@"address" city:@"city" postalCode:@"12190" countryCode:@"IDN"];
          MidtransCustomerDetails *custDetail = [[MidtransCustomerDetails alloc] initWithFirstName:customer[@"first_name"] lastName: customer[@"last_name"] email: customer[@"email"] phone: customer[@"phone"] shippingAddress:address billingAddress:address];
          MidtransTransactionDetails *transDetail = [MidtransTransactionDetails alloc];
          [transDetail initWithOrderID: json[@"order_id"] andGrossAmount: json[@"total"]];
          NSMutableArray *arr = [NSMutableArray new];
          NSArray *items = json[@"items"];
          for(int i = 0; i < [items count]; i++) {
              NSDictionary *itemJson = items[i];
              MidtransItemDetail *item = [MidtransItemDetail alloc];
              [item initWithItemID:itemJson[@"id"] name:itemJson[@"name"] price: itemJson[@"price"] quantity:itemJson[@"quantity"]];
              [arr addObject:item];
          }
          NSMutableArray *arrayOfCustomField = [NSMutableArray new];
          [arrayOfCustomField addObject:@{MIDTRANS_CUSTOMFIELD_1:json[@"custom_field_1"]}];
          [arrayOfCustomField addObject:@{MIDTRANS_CUSTOMFIELD_2:@""}];
          [arrayOfCustomField addObject:@{MIDTRANS_CUSTOMFIELD_3:@""}];
          [[MidtransMerchantClient shared] requestTransactionTokenWithTransactionDetails:transDetail itemDetails:arr customerDetails:custDetail customField:arrayOfCustomField binFilter:nil blacklistBinFilter:nil transactionExpireTime:nil completion:^(MidtransTransactionTokenResponse *token, NSError *error)
           {
               if (token) {
                   MidtransUIPaymentViewController *vc = [[MidtransUIPaymentViewController new] initWithToken:token];
                   vc.paymentDelegate = delegate;
                   UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
                   [viewController presentViewController:vc animated:YES completion:nil];
               }
           }];
          return result(0);
      }
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
