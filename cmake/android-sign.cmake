message("into android-sign.cmake")

set(APK_UNSIGNED ${CMAKE_CURRENT_BINARY_DIR}/android-build-appZhome/build/outputs/apk/release/android-build-appZhome-release-unsigned.apk)
set(APK_SIGNED ${CMAKE_CURRENT_BINARY_DIR}/android-build-appZhome/build/outputs/apk/release/android-build-appZhome-release-signed.apk)
set(KEY_STORE_FILE ${CMAKE_SOURCE_DIR}/cfg/android-release-key.keystore)

# Passwords and DN must come from the environment — never hardcode secrets.
#   ANDROID_KEYSTORE_STORE_PASS, ANDROID_KEYSTORE_KEY_PASS
#   ANDROID_KEYSTORE_DNAME (optional, for keytool -genkey)
#   ANDROID_SERIAL (optional, for adb -s)

if(NOT EXISTS "${KEY_STORE_FILE}")
    if(NOT DEFINED ENV{ANDROID_KEYSTORE_STORE_PASS} OR NOT DEFINED ENV{ANDROID_KEYSTORE_KEY_PASS})
        message(FATAL_ERROR "Keystore missing and ANDROID_KEYSTORE_STORE_PASS / ANDROID_KEYSTORE_KEY_PASS not set")
    endif()
    set(_DNAME "$ENV{ANDROID_KEYSTORE_DNAME}")
    if(_DNAME STREQUAL "")
        set(_DNAME "CN=ZHome, OU=dev, O=iThingTalk, C=CN")
    endif()
    message(STATUS "Creating new keystore (passwords from environment)...")
    execute_process(
        COMMAND keytool -genkey -v -keystore ${KEY_STORE_FILE}
                -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000
                -storepass "$ENV{ANDROID_KEYSTORE_STORE_PASS}" -keypass "$ENV{ANDROID_KEYSTORE_KEY_PASS}"
                -dname "${_DNAME}"
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        RESULT_VARIABLE KEYTOOL_RESULT
    )
    if(KEYTOOL_RESULT EQUAL 0)
        message(STATUS "Keystore created successfully")
    else()
        message(FATAL_ERROR "Failed to create keystore")
    endif()
endif()

if(ANDROID AND CMAKE_BUILD_TYPE STREQUAL "Release")
    set(ANDROID_MIN_SDK_VERSION 21)
    set(ANDROID_TARGET_SDK_VERSION 30)
    set(ANDROID_KEYSTORE_ALIAS "my-key-alias")
    if(NOT DEFINED ENV{ANDROID_KEYSTORE_STORE_PASS} OR NOT DEFINED ENV{ANDROID_KEYSTORE_KEY_PASS})
        message(FATAL_ERROR "ANDROID_KEYSTORE_STORE_PASS / ANDROID_KEYSTORE_KEY_PASS required for Release signing")
    endif()
    set(ANDROID_KEYSTORE_STORE_PASS "$ENV{ANDROID_KEYSTORE_STORE_PASS}")
    set(ANDROID_KEYSTORE_KEY_PASS "$ENV{ANDROID_KEYSTORE_KEY_PASS}")
    set(ANDROID_KEYSTORE_PATH "${KEY_STORE_FILE}")

    find_program(APKSIGNER_EXECUTABLE
        NAMES apksigner
        PATHS ${ANDROID_SDK_ROOT}/build-tools/*/ ${ANDROID_SDK_ROOT}/build-tools/*/
        NO_DEFAULT_PATH
    )

    message("APKSIGNER_EXECUTABLE: ${APKSIGNER_EXECUTABLE}")

    set(_ADB_INSTALL ${ANDROID_SDK_ROOT}/platform-tools/adb install -r ${APK_SIGNED})
    if(DEFINED ENV{ANDROID_SERIAL} AND NOT "$ENV{ANDROID_SERIAL}" STREQUAL "")
        set(_ADB_INSTALL ${ANDROID_SDK_ROOT}/platform-tools/adb -s $ENV{ANDROID_SERIAL} install -r ${APK_SIGNED})
    endif()

    add_custom_command(TARGET appZhome POST_BUILD
        COMMENT "Signing APK"
        COMMAND ${APKSIGNER_EXECUTABLE} sign
            --ks ${ANDROID_KEYSTORE_PATH}
            --ks-key-alias ${ANDROID_KEYSTORE_ALIAS}
            --ks-pass pass:${ANDROID_KEYSTORE_STORE_PASS}
            --key-pass pass:${ANDROID_KEYSTORE_KEY_PASS}
            --out ${APK_SIGNED}
            ${APK_UNSIGNED}
        COMMENT "Verifying APK"
        COMMAND ${APKSIGNER_EXECUTABLE} verify ${APK_SIGNED}
        COMMENT "Installing APK"
        COMMAND ${_ADB_INSTALL}
        VERBATIM
    )
endif()

message("android-sign.cmake done")
