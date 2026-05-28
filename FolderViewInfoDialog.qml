import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Widgets
import qs.Services
import "../dms-common"

Popup {
    id: infoDialog
    width: 320
    height: contentColumn.implicitHeight + Theme.spacingM * 2
    padding: 0
    modal: false
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0

    property string filePath: ""
    property string fileName: ""
    property string fileInfo: "Loading..."
    property bool isDir: false

    background: Rectangle {
        color: "transparent"
    }

    contentItem: Rectangle {
        color: Theme.surfaceContainer
        radius: Theme.cornerRadius
        border.color: Theme.withAlpha(Theme.outline, 0.15)
        border.width: 1

        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM

            Row {
                width: parent.width
                spacing: Theme.spacingS

                DankIcon {
                    name: infoDialog.isDir ? "folder" : "description"
                    size: 24
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: infoDialog.fileName
                    font.bold: true
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    width: parent.width - 32
                    elide: Text.ElideMiddle
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.withAlpha(Theme.outline, 0.1)
            }

            StyledText {
                width: parent.width
                text: infoDialog.fileInfo
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.Wrap
                lineHeight: 1.4
            }

            DankButton {
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.tr("Close")
                backgroundColor: Theme.surfaceContainerHigh
                textColor: Theme.surfaceText
                onClicked: infoDialog.close()
            }
        }
    }

    function showFor(path, name, isDirectory) {
        let cleanPath = String(path);
        if (cleanPath.startsWith("file://")) {
            cleanPath = cleanPath.substring(7);
        }
        if (cleanPath.startsWith("localhost/")) {
            cleanPath = cleanPath.substring(9);
        }
        
        infoDialog.filePath = cleanPath;
        infoDialog.fileName = name;
        infoDialog.isDir = !!isDirectory;
        infoDialog.fileInfo = "Loading...";
        infoDialog.open();

        fetchInfo();
    }

    function fetchInfo() {
        const path = infoDialog.filePath;
        // Get basic info with stat
        // %F: type, %A: permissions, %y: last modified, %s: size in bytes
        const statCmd = ["stat", "-c", "Type: %F\nPermissions: %A\nModified: %y\nSize: %s bytes", path];
        
        Proc.runCommand("get-file-info", statCmd, (output, exitCode) => {
            if (exitCode === 0) {
                let info = output.trim();
                
                if (infoDialog.isDir) {
                    // For directories, also get human readable size with du
                    Proc.runCommand("get-dir-size", ["du", "-sh", path], (duOutput, duExit) => {
                        if (duExit === 0) {
                            const size = duOutput.trim().split(/\s+/)[0];
                            info = info.replace(/Size:.*bytes/, "Size: " + size);
                        }
                        infoDialog.fileInfo = info + "\nPath: " + path;
                    });
                } else {
                    // For files, get human readable size with ls -lh
                    Proc.runCommand("get-file-size", ["ls", "-lh", path], (lsOutput, lsExit) => {
                        if (lsExit === 0) {
                            const parts = lsOutput.trim().split(/\s+/);
                            if (parts.length >= 5) {
                                const size = parts[4];
                                info = info.replace(/Size:.*bytes/, "Size: " + size);
                            }
                        }
                        infoDialog.fileInfo = info + "\nPath: " + path;
                    });
                }
            } else {
                infoDialog.fileInfo = "Error fetching info for: " + path;
            }
        });
    }
}
