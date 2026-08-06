
if(LINUX AND NOT ANDROID)
    find_package(X11 REQUIRED)
    find_package(Qt6 COMPONENTS DBus Gui REQUIRED)
    target_link_libraries(appZhome PRIVATE
        X11::X11
        Qt6::DBus
        Qt6::Gui
    )
    if(X11_FOUND)
        target_include_directories(appZhome PRIVATE
            ${X11_INCLUDE_DIR}
            ${Qt6Gui_PRIVATE_INCLUDE_DIRS}
        )
        target_compile_definitions(appZhome PRIVATE X11_AVAILABLE)
    endif()
    # target_compile_definitions(appZhome PRIVATE _GNU_SOURCE=1)
endif()
