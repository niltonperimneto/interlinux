import QtQuick 2.0
import SddmComponents 2.0

Rectangle {

    Loader {
        source: "file:///usr/share/sddm/themes/breeze/Main.qml"
    }

    Image {
        id: background
        z: -1 // Place the image behind all other elements

        source: "file:///usr/share/wallpapers/inglesinternational.png"

        fillMode: Image.PreserveAspectCrop // Cover the screen without distortion
        anchors.fill: parent 
    }
}