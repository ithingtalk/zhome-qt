if(APPLE AND NOT IOS) # macos
    # screen saver
    find_library(IOKIT_LIBRARY IOKit)
    find_library(COREFOUNDATION_LIBRARY CoreFoundation)
    target_link_libraries(appZhome PRIVATE ${IOKIT_LIBRARY} ${COREFOUNDATION_LIBRARY})
    # configure file
    set_target_properties(appZhome PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/platform-macos/Info.plist
    )
    add_custom_command(TARGET appZhome POST_BUILD
        COMMAND codesign -s "$ENV{MACOS_CODESIGN_IDENTITY}" $<TARGET_BUNDLE_DIR:appZhome>
        COMMENT "Post build: code sign"
        VERBATIM
    )
endif()

set_target_properties(appZhome PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.ithingtalk.zhome
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    # IOS_DEPLOYMENT_TARGET "16.0"
    # MACOSX_BUNDLE_BUNDLE_NAME com.ithingtalk.zhome
    # MACOSX_BUNDLE_COPYRIGHT "Copyright © 2024, iThingTalk"
    # MACOSX_BUNDLE_ICON_FILE appZhome.icns
    # MACOSX_BUNDLE_INFO_STRING "Zhome"
    # MACOSX_BUNDLE_LONG_VERSION_STRING ${PROJECT_VERSION}
    MACOSX_BUNDLE TRUE
)
