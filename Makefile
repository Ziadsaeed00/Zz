# إجبار نظام البناء على وضع الـ Release وإيقاف الـ Debug تماماً
DEBUG = 0
FINALPACKAGE = 1

TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CodebySMSTweak

CodebySMSTweak_FILES = Tweak.xm
CodebySMSTweak_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
