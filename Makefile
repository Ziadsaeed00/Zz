TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CodebySMSTweak

CodebySMSTweak_FILES = Tweak.xm
CodebySMSTweak_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
