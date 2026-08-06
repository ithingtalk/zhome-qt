
if (ANDROID)
    # screen saver
    #target_compile_definitions(appZhome PRIVATE
    #    QT_ANDROID_DISABLE_MAKE_KEEP_SCREEN_ON=1
    #)
    # add java call support
    # target_link_libraries(appZhome PRIVATE Qt6::CorePrivate android)

    include(${ANDROID_SDK_ROOT}/android_openssl/android_openssl.cmake)
    add_android_openssl_libraries(appZhome)

    set_target_properties(appZhome PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR ${CMAKE_SOURCE_DIR}/platform-android
        QT_ANDROID_PACKAGE_NAME "com.ithingtalk.zhome"
        QT_ANDROID_MIN_SDK_VERSION 21
        QT_ANDROID_TARGET_SDK_VERSION 30
        QT_ANDROID_COMPILE_SDK_VERSION 30
        QT_ANDROID_VERSION_CODE 10
        QT_ANDROID_VERSION_NAME "1.0"
        #QT_ANDROID_SERVICE "org.qtproject.qt.android.bindings.QtService"
    )
    # qt_import_plugins(appZhome
    #    INCLUDE_BY_TYPE imageformats Qt::QSvgPlugin
    #    EXCLUDE_BY_TYPE qmltooling
    #    EXCLUDE_BY_TYPE iconengines
    #    EXCLUDE_BY_TYPE networkinformation
    #    EXCLUDE_BY_TYPE tls
    #    EXCLUDE_BY_TYPE platforminputcontexts
    #)
endif()
