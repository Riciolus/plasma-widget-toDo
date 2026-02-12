import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

    // Properti utama
    preferredRepresentation: compactRepresentation

    // ListModel sebagai sumber data tunggal
    ListModel {
        id: todoModel
    }

    // Fungsi untuk sinkronisasi ke konfigurasi plasmoid (persisten)
    function saveTodos() {
        let arr = []
        for (let i = 0; i < todoModel.count; i++) {
            // Kita ambil objek data murni dari model
            let item = todoModel.get(i)
            arr.push({
                "text": item.text,
                "done": item.done
            })
        }
        plasmoid.configuration.todos = arr
    }

    // Load data saat komponen selesai dibuat
    Component.onCompleted: {
        const savedTodos = plasmoid.configuration.todos
        if (savedTodos) {
            for (let i = 0; i < savedTodos.length; i++) {
                todoModel.append(savedTodos[i])
            }
        }
    }

    // Tampilan saat di Panel (Icon)
    // Tampilan saat di Panel (Icon)
    compactRepresentation: Item {
        // Biar ukuran icon-nya pas sama panel KDE
        width: Kirigami.Units.gridUnit * 2
        height: Kirigami.Units.gridUnit * 2

        Kirigami.Icon {
            anchors.fill: parent
            source: "view-pim-tasks"
            // Gunakan 'active' (bukan activeState) untuk highlight saat popup buka
            active: root.expanded 
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }

    // Tampilan saat di klik/pop-up
    fullRepresentation: Frame {
    width: Kirigami.Units.gridUnit * 20
    height: Kirigami.Units.gridUnit * 25

    padding: 14

    // Hapus border popup container
    background: Rectangle {
        radius: 14
        color: "transparent"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        TextField {
            id: input
            placeholderText: "Add new task..."
            Layout.fillWidth: true

            onAccepted: {
                if (text.trim() !== "") {
                    todoModel.append({
                        "text": text,
                        "done": false
                    })
                    saveTodos()
                    text = ""
                }
            }
        }

        // Title
        Label {
            text: "Your To Do"
            font.bold: true
            font.pointSize: 11
            opacity: 0.85
            Layout.topMargin: 4
        }

        // Separator tipis
        Rectangle {
            Layout.fillWidth: true
            height: 1
            radius: 1
            color: Qt.rgba(1, 1, 1, 0.12)   // putih tipis untuk dark theme
            Layout.topMargin: 4
            Layout.bottomMargin: 5
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Label {
                anchors.centerIn: parent
                text: "No tasks yet 🎉"
                visible: todoModel.count === 0
                opacity: 0.5
            }

            ListView {
                id: listView
                anchors.fill: parent
                model: todoModel
                clip: true

                spacing: 4   // sebelumnya 10 → sekarang lebih rapat

                delegate: ItemDelegate {
                    width: listView.width
                    padding: 10

                    background: Rectangle {
                        radius: 10
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.14)
                        color: "transparent"
                    }

                    contentItem: RowLayout {
                        spacing: 8

                        CheckBox {
                            checked: model.done
                            onToggled: {
                                todoModel.setProperty(index, "done", checked)
                                saveTodos()
                            }
                        }

                        Label {
                            text: model.text
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.strikeout: model.done
                            opacity: model.done ? 0.5 : 1.0
                            verticalAlignment: Text.AlignVCenter
                        }

                        ToolButton {
                            icon.name: "edit-delete"
                            onClicked: {
                                todoModel.remove(index)
                                saveTodos()
                            }
                        }
                    }
                }
            }
        }
    }
}


}