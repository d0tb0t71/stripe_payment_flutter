import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:stripe_test/stripe/constant.dart';
import 'package:stripe_test/stripe/payment_form.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = "pk_test_51K0K5nLSY0NZTq27mHLjbuNvTFMjEBZeu6wW1AAZmyB5Lbf6W4IgaYjl5f1CyBZLflz8QwD0o0GOqqpQnl8PWss000Qs26SAhU";
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Map<String , dynamic>? paymentIntent;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        title: Text(widget.title),
      ),
      body: Center(

        child: ElevatedButton(onPressed: () async {
          await makePayment();
        }, child: Text("Make Payment")),
      ),
    );
  }

  Future<void> makePayment() async {
    try{
      paymentIntent = await createPaymentIntent("10" , "USD");
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntent!['client_secret'],
              //applePay: const PaymentSheetApplePay(merchantCountryCode: '+880'),
              //googlePay: const PaymentSheetGooglePay(merchantCountryCode: '+880'),
              style: ThemeMode.dark,
              merchantDisplayName: "LU Debugger"
          )
      );

      displayPaymentSheet();
    } catch( error , s){
      print("Exception found ${error.toString()}");
    }

  }

  createPaymentIntent(String amount, String currency) async {

    try{
      Map<String , dynamic> body = {
        'amount' : calculateAmount(amount),
        'currency' : currency,
        'payment_method_types[]' : 'card'
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization' : 'Bearer $SECRET_KEY',
          'Content-Type' : 'application/x-www-form-urlencoded'

        },
        body: body,
      );

      print(response.body);
      return jsonDecode(response.body);

    }
    catch (error) {
      print("Error Charging the user ${error.toString()}");
    }

  }

  calculateAmount(String amount) {

    final calculatedAmount = ( int.parse(amount)) * 100;
    return calculatedAmount.toString();
  }

   displayPaymentSheet() async {
    try{
      await Stripe.instance.presentPaymentSheet(

      ).then((value) => {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle , color: Colors.grey,),
                Text("Payment Successful"),
                ElevatedButton(onPressed: (){

                }, child: Text("Done"))
              ],
            ),
          )
        )
      });

      paymentIntent = null;
    } on StripeException catch (error){
      print("Error $error");
      showDialog(context: context, builder: (_) => AlertDialog(
        content: Text("Cancelled"),
      ));
    }
   }
}
