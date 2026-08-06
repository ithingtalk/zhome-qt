include_guard()

message(STATUS "header.cmake")

if(WIN32)
    message("Plateform WIN")
    set(LIB_SUB_DIR "win")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__WIN__")
elseif(IOS)
    message("Plateform IOS")
    set(LIB_SUB_DIR "ios")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__IOS__ -D__APPLE__")
elseif(APPLE AND NOT IOS)
    message("Plateform OSX")
    set(LIB_SUB_DIR "osx")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__OSX__ -D__APPLE__")
elseif(ANDROID)
    message("Plateform ANDROID")
    set(LIB_SUB_DIR "android")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__ANDROID__")
else()
    message("Plateform LINUX")
    set(LIB_SUB_DIR "linux")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__LINUX__")
endif()

set(LIBS_Dir "${CMAKE_SOURCE_DIR}/thirdparty/${LIB_SUB_DIR}")

message("LIBS_Dir: ${LIBS_Dir}")

# use boringssl instead openssl for libaws
set(CMAKE_PREFIX_PATH "${LIBS_Dir};${CMAKE_PREFIX_PATH}")
set(CMAKE_LIBRARY_PATH "${LIBS_Dir}/lib;${CMAKE_LIBRARY_PATH}")
set(CMAKE_INCLUDE_PATH "${LIBS_Dir}/include;${CMAKE_INCLUDE_PATH}")
include_directories(${LIBS_Dir}/include)
add_compile_options(-DPJ_HAS_LIMITS_H=1)

set(P2P_THREAD_LIBS "")
if(CMAKE_C_COMPILER_LOADED OR CMAKE_CXX_COMPILER_LOADED)
    find_package(Threads)
endif()
if(Threads_FOUND)
    set(P2P_THREAD_LIBS Threads::Threads)
elseif(UNIX AND NOT APPLE)
    set(P2P_THREAD_LIBS pthread)
endif()

if(IOS)

    message("ios ...")
    set(LIBS_ALL
        ${LIBS_Dir}/lib/liblsquic.a
        ${LIBS_Dir}/lib/libssl.a
        ${LIBS_Dir}/lib/libcrypto.a
        ${LIBS_Dir}/lib/libjuice.a
        ${LIBS_Dir}/lib/libuv.a
        ${P2P_THREAD_LIBS}
    )

elseif(APPLE)

    message("osx ...")
    set(LIBS_ALL
        ${LIBS_Dir}/lib/liblsquic.a
        ${LIBS_Dir}/lib/libssl.a
        ${LIBS_Dir}/lib/libcrypto.a
        ${LIBS_Dir}/lib/libjuice.a
        ${LIBS_Dir}/lib/libuv.a
        ${P2P_THREAD_LIBS}
    )

elseif(ANDROID)

    message("android ...")
    set(LIBS_ALL
        ${LIBS_Dir}/lib/liblsquic.a
        ${LIBS_Dir}/lib/libssl.a
        ${LIBS_Dir}/lib/libcrypto.a
        ${LIBS_Dir}/lib/libjuice.a
        ${LIBS_Dir}/lib/libuv.a
        ${P2P_THREAD_LIBS}
        log
        z
    )

elseif(WIN32)

    message("windows ...")

    SET(MY_CMAKE_FLAGS "${MY_CMAKE_FLAGS} /wd4100 /wd4115 /wd4116 /wd4132 /wd4200 /wd4204 /wd4244 /wd4245 /wd4267 /wd4214 /wd4295 /wd4324 /wd4334 /wd4456 /wd4459 /wd4706 /wd4090 /wd4305 /wd4201 /wd4819")
    SET(MY_CMAKE_FLAGS "${MY_CMAKE_FLAGS} /WX /DWIN32_LEAN_AND_MEAN /DNOMINMAX /D_CRT_SECURE_NO_WARNINGS /I${CMAKE_SOURCE_DIR}/wincompat")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${MY_CMAKE_FLAGS}")
    find_library(LSQUIC_LIB              NAMES lsquic           PATHS ${LIBS_Dir}/lib         NO_DEFAULT_PATH    REQUIRED)
    find_library(BORINGSSL_SSL_LIB       NAMES ssl              PATHS ${LIBS_Dir}/lib         NO_DEFAULT_PATH    REQUIRED)
    find_library(BORINGSSL_CRYPTO_LIB    NAMES crypto           PATHS ${LIBS_Dir}/lib         NO_DEFAULT_PATH    REQUIRED)

    find_library(Z_LIB                   NAMES zs               PATHS ${LIBS_Dir}/lib         NO_DEFAULT_PATH    REQUIRED)

    set(LIBS_ALL 
        ${LSQUIC_LIB}
        ${BORINGSSL_SSL_LIB}
        ${BORINGSSL_CRYPTO_LIB}
        ${LIBS_Dir}/lib/juice.lib
        ${LIBS_Dir}/lib/libuv.lib
        ${P2P_THREAD_LIBS}
        ${Z_LIB}
        ws2_32
        iphlpapi
        dbghelp
    )

else() # Linux

    message("linux ...")

    find_library(LSQUIC_LIB              NAMES lsquic           PATHS ${LIBS_Dir}/lib         NO_DEFAULT_PATH    REQUIRED)
    find_library(BORINGSSL_SSL_LIB       NAMES ssl              PATHS ${LIBS_Dir}/lib         NO_DEFAULT_PATH    REQUIRED)
    find_library(BORINGSSL_CRYPTO_LIB    NAMES crypto           PATHS ${LIBS_Dir}/lib         NO_DEFAULT_PATH    REQUIRED)
    find_library(LSJUICE_LIB             NAMES juice            PATHS ${LIBS_Dir}/lib         NO_DEFAULT_PATH    REQUIRED)
    find_library(UV_LIB                  NAMES uv               PATHS ${LIBS_Dir}/lib         NO_DEFAULT_PATH    REQUIRED)
    find_library(Z_LIB                   NAMES z)
    find_library(M_LIB                   NAMES m)
    find_library(RT_LIB                  NAMES rt)
    # find_library(PTHREAD_LIB             NAMES pthread)
    set(LIBS_ALL 
        ${LSQUIC_LIB}
        ${BORINGSSL_SSL_LIB}
        ${BORINGSSL_CRYPTO_LIB}
        ${LSJUICE_LIB}
        ${UV_LIB}
        ${P2P_THREAD_LIBS}
        ${Z_LIB}
        ${M_LIB}
        ${RT_LIB}
        # ${PTHREAD_LIB}
    )

endif()

message("LIBS_ALL: ${LIBS_ALL}")
