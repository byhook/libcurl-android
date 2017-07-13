LOCAL_PATH := $(call my-dir)

#libcurl库
include $(CLEAR_VARS)
LOCAL_MODULE := libcurl
LOCAL_SRC_FILES := $(LOCAL_PATH)/armeabi-v7a/lib/libcurl.a 
include $(PREBUILT_STATIC_LIBRARY) 


#测试程序(以armeabi-v7a为例)
include $(CLEAR_VARS)
LOCAL_MODULE := main
LOCAL_SRC_FILES := main.cpp
LOCAL_C_INCLUDES += $(LOCAL_PATH)/armeabi-v7a/include
LOCAL_LDLIBS := -llog -lz
LOCAL_STATIC_LIBRARIES := libcurl

LOCAL_CFLAGS += -pie -fPIE
LOCAL_LDFLAGS += -pie -fPIE

include $(BUILD_EXECUTABLE)
