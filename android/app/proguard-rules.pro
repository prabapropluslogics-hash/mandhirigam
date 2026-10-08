# Razorpay Checkout (razorpay_flutter → com.razorpay:checkout).
# Rules from Razorpay's Android integration guide; required when R8 shrinks
# the release build, otherwise checkout callbacks can be stripped.
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
    public void onPayment*(...);
}

# Google Pay (UPI intent) classes referenced by Razorpay but not bundled.
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**
