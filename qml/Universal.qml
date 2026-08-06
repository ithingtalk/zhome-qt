import QtQuick.Controls.Universal

ZhomeMain {
    onSetTheme: function () {
        console.log("universal onSetTheme")
        Universal.theme = Universal.System
    }
}
