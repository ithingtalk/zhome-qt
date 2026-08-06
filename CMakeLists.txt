cmake_minimum_required(VERSION 3.16)

set(APP_VER 0.1.5)
if(IOS)
    project(Zhome VERSION ${APP_VER} LANGUAGES C CXX OBJCXX)
else()
    project(Zhome VERSION ${APP_VER} LANGUAGES C CXX)
endif()

find_package(Qt6 REQUIRED COMPONENTS Quick Sql Core Qml QuickControls2 Multimedia Network LinguistTools Gui)

qt_standard_project_setup(REQUIRES 6.8)

include(header.cmake)

# zlib
if(WIN32)
    if(NOT TARGET ZLIB::ZLIB)
        add_library(ZLIB::ZLIB UNKNOWN IMPORTED)
        set_target_properties(ZLIB::ZLIB PROPERTIES
            IMPORTED_LOCATION "${LIBS_Dir}/lib/zs.lib"
            INTERFACE_INCLUDE_DIRECTORIES "${LIBS_Dir}/include"
        )
    endif()
else()
    find_package(ZLIB REQUIRED)
    include_directories(${ZLIB_INCLUDE_DIRS})
endif()

# aws libs
if(IOS OR ANDROID)
    link_directories(${LIBS_Dir}/lib)
    link_directories(${LIBS_Dir}/bin)
    include_directories(${LIBS_Dir}/include)
else()
    list(APPEND CMAKE_PREFIX_PATH "${LIBS_Dir}/lib/cmake")
    find_package(AWSSDK REQUIRED COMPONENTS core cognito-idp cognito-identity sts apigateway)
    include_directories(${AWSSDK_INCLUDE_DIRS})
    link_directories(${AWSSDK_LIB_DIR})

    # use boringssl instead openssl
    # set(CMAKE_PREFIX_PATH "${LIBS_Dir};${CMAKE_PREFIX_PATH}")
    # set(CMAKE_LIBRARY_PATH "${LIBS_Dir}/lib;${CMAKE_LIBRARY_PATH}")
    # set(CMAKE_INCLUDE_PATH "${LIBS_Dir}/include;${CMAKE_INCLUDE_PATH}")

    message("CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")
    message("CMAKE_LIBRARY_PATH: ${CMAKE_LIBRARY_PATH}")
    message("CMAKE_INCLUDE_PATH: ${CMAKE_INCLUDE_PATH}")

    message("AWSSDK_INCLUDE_DIRS: ${AWSSDK_INCLUDE_DIRS}")
    message("AWSSDK_LIB_DIR: ${AWSSDK_LIB_DIR}")
    message("AWSSDK_BIN_DIR: ${AWSSDK_BIN_DIR}")
endif()

if(ANDROID)
    set(S2N_LIB s2n)
elseif(NOT WIN32)
    set(PTHREAD_NAME pthread)
endif()

include_directories(
    ${CMAKE_SOURCE_DIR}/p2p-src/p2p
    ${CMAKE_SOURCE_DIR}/p2p-src/p2p/include
    ${CMAKE_SOURCE_DIR}/cpp
    ${CMAKE_SOURCE_DIR}/iot
)

if(WIN32)
    set(app_icon_resource_windows "${CMAKE_SOURCE_DIR}/icons/icon/windows/logo.rc")
    qt_add_executable(appZhome cpp/main.cpp ${app_icon_resource_windows})
elseif(APPLE)
    add_compile_options(-fobjc-arc)
    # set(MACOSX_BUNDLE_ICON_FILE logo.icns) # moved in info.plist, just copy file to Resources
    set(app_icon_macos "${CMAKE_SOURCE_DIR}/icons/icon/macos/logo.icns")
    set_source_files_properties(${app_icon_macos} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
    qt_add_executable(appZhome MACOSX_BUNDLE cpp/main.cpp ${app_icon_macos})
else()
    qt_add_executable(appZhome cpp/main.cpp)
endif()

qt_add_translations(appZhome TS_FILES qml/Zhome_zh_CN.ts)

include(${CMAKE_SOURCE_DIR}/cmake/files.cmake)

qt_add_qml_module(appZhome
    URI Zhome
    VERSION 1.0
    QML_FILES ${MY_QML_FILES}
    SOURCES ${MY_SOURCES}
    RESOURCES
        qml/Global/qmldir
        cfg/config.json
        cfg/awsconfig.json
        ${MY_ICONS}
)

target_compile_definitions(appZhome PRIVATE
    $<$<PLATFORM_ID:Windows>:QT_WIN32_CORE_SUPPORT>
    $<$<PLATFORM_ID:Linux>:QT_X11_EXTRAS_LIB>
)

include(${CMAKE_SOURCE_DIR}/cmake/${LIB_SUB_DIR}.cmake)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DEXCLUDE_MY_CJSON")

#######################################################################################
if(1) # (IOS OR ANDROID)
	target_compile_definitions(appZhome PRIVATE QZXING_USE_ENCODER)
	if(IOS OR ANDROID)
	    target_compile_definitions(appZhome PRIVATE QZXING_MULTIMEDIA)
	endif()
	add_subdirectory(qzxing)
	set(XING_LIB qzxing)
	# C++ / MOC must see HAS_QZXING (was only on CMAKE_C_FLAGS, so utils.cpp could omit qrEncode).
	target_compile_definitions(appZhome PRIVATE HAS_QZXING)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DHAS_QZXING")
endif()
#######################################################################################
if(0)
add_subdirectory(samegame)
set(SAMEGAME_LIB samegame)
endif()

target_link_libraries(appZhome PRIVATE
    Qt6::Quick Qt6::Sql Qt6::Core Qt6::Qml Qt6::QuickControls2 Qt6::Multimedia Qt6::Network Qt6::Gui
    aws-cpp-sdk-cognito-idp aws-cpp-sdk-cognito-identity aws-cpp-sdk-sts aws-cpp-sdk-apigateway aws-cpp-sdk-core
    aws-crt-cpp aws-c-http aws-c-mqtt aws-c-cal aws-c-auth aws-c-common aws-c-io aws-checksums aws-c-event-stream
    aws-c-s3 aws-c-compression aws-c-sdkutils
    ${S2N_LIB}
    ${PTHREAD_NAME}
    ip2p
    ${LIBS_ALL}
    ${XING_LIB}
    ${SAMEGAME_LIB}
)

include(GNUInstallDirs)

install(TARGETS appZhome
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

target_compile_definitions(appZhome PRIVATE
    QT_QML_DIR="${CMAKE_SOURCE_DIR}/qml"
)
