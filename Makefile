include theos/makefiles/common.mk

TWEAK_NAME = BackForwardEnhancer
BackForwardEnhancer_FILES = Tweak.xm SA_ActionSheet.m
BackForwardEnhancer_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
