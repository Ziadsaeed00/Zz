ARCHS = arm64 arm64e
TARGET := iphone:clang:raw:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CodebySMSTweak
CodebySMSTweak_FILES = Tweak.xm
CodebySMSTweak_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
