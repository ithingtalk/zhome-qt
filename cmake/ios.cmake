
if(IOS)
    ### music player
    find_library(AVFOUNDATION AVFoundation)
    find_library(MEDIAPLAYER MediaPlayer)
    find_library(UIKIT UIkit)
    find_library(PHOTOSUI_FRAMEWORK PhotosUI)
    target_link_libraries(appZhome PRIVATE ${AVFOUNDATION} ${MEDIAPLAYER} ${UIKIT} ${PHOTOSUI_FRAMEWORK})
    # ffmpeg support
    qt_add_ios_ffmpeg_libraries(appZhome)
    set_target_properties(appZhome PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/platform-ios/Info.plist
        XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS ${CMAKE_SOURCE_DIR}/platform-ios/appZhome.entitlements
    )
    # Add resource files to the Xcode project
    set(RESOURCE_FILES "icons/changpian.png")
    set_source_files_properties(${RESOURCE_FILES} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
    target_sources(appZhome PRIVATE ${RESOURCE_FILES})

    # set(asset_catalog_path "platform-ios/Assets.xcassets")
    # target_sources(appZhome PRIVATE "${asset_catalog_path}")
    # set_source_files_properties(${asset_catalog_path} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
    # set_target_properties(appZhome PROPERTIES XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME AppIcon)
endif()

set_target_properties(appZhome PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.ithingtalk.zhome
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    # IOS_DEPLOYMENT_TARGET "18.6"
    # MACOSX_BUNDLE_BUNDLE_NAME com.ithingtalk.zhome
    # MACOSX_BUNDLE_COPYRIGHT "Copyright © 2024, iThingTalk"
    # MACOSX_BUNDLE_ICON_FILE appZhome.icns
    # MACOSX_BUNDLE_INFO_STRING "Zhome"
    # MACOSX_BUNDLE_LONG_VERSION_STRING ${PROJECT_VERSION}
    MACOSX_BUNDLE TRUE
)
