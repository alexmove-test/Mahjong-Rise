# WorkManager (transitive via google_mobile_ads / play-services-ads) under AGP 9 R8 full mode.
# Without these rules R8 can strip WorkDatabase_Impl's reflective constructor.
# https://github.com/googleads/googleads-mobile-flutter/issues/1444
-keep class androidx.work.impl.** { *; }
-dontwarn androidx.work.impl.**

-keep class * extends androidx.room.RoomDatabase
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
