import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.bar
import qs.services

// Reproductor: carátula, tema, progreso y controles.
Card {
    id: root

    title: Tr.f("Música · %1", Media.player?.identity ?? "")
    visible: Media.active

    RowLayout {
        spacing: 12
        Layout.fillWidth: true

        Rectangle {
            implicitWidth: 64; implicitHeight: 64
            radius: Theme.radiusInner
            color: Theme.surface2
            clip: true

            Image {
                anchors.fill: parent
                source: Media.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
            Icon {
                anchors.centerIn: parent
                code: 0xF075A
                color: Theme.dim
                visible: !(Media.player?.trackArtUrl)
            }
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Label { text: Media.title || Tr.t("Sin título"); font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
            Label { text: Media.artist; muted: true; elide: Text.ElideRight; Layout.fillWidth: true }
        }
    }

    ColumnLayout {
        spacing: 4
        Layout.fillWidth: true

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 4; radius: 2
            color: Theme.surface2
            Rectangle {
                width: parent.width * Media.progress
                height: parent.height; radius: 2
                color: Theme.accent
            }
        }
        RowLayout {
            Label { text: Media.fmt(Media.player?.position); mono: true; muted: true; font.pixelSize: Theme.fontSize - 3; Layout.fillWidth: true }
            Label { text: Media.fmt(Media.player?.length); mono: true; muted: true; font.pixelSize: Theme.fontSize - 3 }
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 10
        Chip { onClicked: Media.player?.previous(); Icon { code: 0xF04AE } }
        Chip {
            active: true
            onClicked: Media.player?.togglePlaying()
            Icon { code: Media.player?.isPlaying ? 0xF03E4 : 0xF040A; color: Theme.accent }
        }
        Chip { onClicked: Media.player?.next(); Icon { code: 0xF04AD } }
    }
}
