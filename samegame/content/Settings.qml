// Copyright (C) 2013 BlackBerry Limited. All rights reserved.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

pragma Singleton
import QtQml
import "../../Zhome/qml/Global"

QtObject {
    property int screenHeight: 480
    property int screenWidth: 320

    property int menuDelay: 500

    property int headerHeight: 36 // 70 on BB10

    property int footerHeight: 36 // 100 on BB10

    property int fontPixelSize: Global.fontSize // 55 on BB10

    property int blockSize: 36 // 64 on BB10

    property int toolButtonHeight: 32 // 64 on BB10

    property int menuButtonSpacing: 50 // 15 on BB10
}
