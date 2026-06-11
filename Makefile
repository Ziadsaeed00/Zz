# تحديد المعماريات المدعومة لأجهزة الآيفون الحديثة
ARCHS = arm64 arm64e

# تحديد إصدار النظام الأدنى للتشغيل
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

# اسم الـ Tweak والملفات البرمجية التابعة له
TWEAK_NAME = AdBypassTweak

AdBypassTweak_FILES = Tweak.x
AdBypassTweak_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
