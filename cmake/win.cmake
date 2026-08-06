# libaws
message(STATUS "win32")

# screen saver
if(WIN32)
    target_link_libraries(appZhome PRIVATE user32)
endif()

set_target_properties(appZhome PROPERTIES
    WIN32_EXECUTABLE TRUE
)
