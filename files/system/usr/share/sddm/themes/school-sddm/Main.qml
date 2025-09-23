import QtQuick 2.0
import SddmComponents 2.0

Rectangle {
    Image {
        id: background
        anchors.fill: parent
        source: "file:///usr/share/wallpapers/Bloqueio.png"
        fillMode: Image.PreserveAspectCrop
        z: -1
    }
    // Add your own login form/components here if needed
}
