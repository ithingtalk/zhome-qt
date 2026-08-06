import QtQuick.Controls.Material

ZhomeMain {
    onSetTheme: function () {
        console.log("Material onSetTheme")
        Material.theme = Material.System
    }
}
